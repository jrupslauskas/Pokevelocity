class CatchesController < ApplicationController
  before_action :require_login

  def new
    @trainer = current_trainer

    # Check if there are any routes in the database
    if Route.count == 0
      redirect_to dashboard_path, alert: "No routes available yet! Please contact an administrator."
      return
    end

    # Auto-unlock gates based on difficulty score
    newly_unlocked = @trainer.auto_unlock_gates!
    if newly_unlocked.any?
      unlock_message = "You unlocked #{newly_unlocked.map(&:name).join(', ')}!"
      # Preserve existing flash message if present
      if flash[:notice].present?
        flash.now[:notice] = "#{flash[:notice]} #{unlock_message}"
      else
        flash.now[:notice] = unlock_message
      end
    end

    # Get all gates ordered by gate number (descending for newest first)
    @gates = Gate.order(gate_number: :desc).includes(:routes)

    # Get next locked gate to show only routes up to that gate
    @next_locked_gate = @trainer.next_locked_gate

    # Get routes that don't require any gate (null or 0 gate_requirement) - always accessible
    # Keep these in ascending order since they're always available
    @always_accessible_routes = Route.where("gate_requirement IS NULL OR gate_requirement = 0")
                                     .order(order: :asc)
                                     .includes(route_encounters: :pokemon)

    # Get accessible routes based on unlocked gates (only up to next locked gate)
    if @next_locked_gate
      # Show routes up to (but not including) the next locked gate
      accessible_gate_numbers = @trainer.unlocked_gates.pluck(:gate_number)
      @gated_routes = Route.where(gate_requirement: accessible_gate_numbers)
                           .where("gate_requirement > 0")
                           .order(order: :desc)
                           .includes(route_encounters: :pokemon)
    else
      # All gates unlocked, show all gated routes (excluding always accessible ones)
      @gated_routes = Route.where("gate_requirement IS NOT NULL AND gate_requirement > 0")
                           .order(order: :desc)
                           .includes(route_encounters: :pokemon)
    end

    # Pre-load trainer data to avoid N+1 queries
    captured_pokemon_ids = @trainer.captures.pluck(:pokemon_id).to_set
    unlocked_gate_numbers = @trainer.gate_unlocks.joins(:gate).pluck('gates.gate_number').to_set
    trainer_items = @trainer.trainer_items.joins(:item).pluck('items.key', :quantity).to_h

    # Track which encounter types the trainer can access based on items
    @has_old_rod = (trainer_items['old_rod'] || 0) > 0
    @has_good_rod = (trainer_items['good_rod'] || 0) > 0
    @has_super_rod = (trainer_items['super_rod'] || 0) > 0
    @has_any_fishing_rod = @has_old_rod || @has_good_rod || @has_super_rod
    @has_surf = (trainer_items['hm_surf'] || 0) > 0

    # For each route, show all Pokemon (including already caught) that meet appearance requirements
    @route_available_pokemon = {}
    @route_available_by_type = {}
    (@always_accessible_routes + @gated_routes).each do |route|
      # Get all Pokemon from encounters that are available for this trainer
      # Using optimized method that doesn't trigger N+1 queries
      available_encounters = route.route_encounters.select do |encounter|
        encounter_available_optimized?(encounter, captured_pokemon_ids, unlocked_gate_numbers, trainer_items)
      end
      @route_available_pokemon[route.id] = available_encounters.map(&:pokemon)

      # Track which encounter types have available Pokemon
      @route_available_by_type[route.id] = {
        'grass' => available_encounters.any? { |e| e.grass? },
        'fish' => available_encounters.any? { |e| e.fish? },
        'surf' => available_encounters.any? { |e| e.surf? }
      }
    end

    # Check if trainer has any pokeballs (show message but don't redirect)
    # Only show this message if there isn't already a flash message
    if @trainer.total_pokeballs == 0 && flash[:alert].nil? && flash[:notice].nil?
      flash.now[:alert] = "You don't have any Pokéballs! Complete tickets to earn some."
    end
  end

  def adventure
    @trainer = current_trainer
    route = Route.find(params[:id])
    encounter_type = params[:encounter_type] || 'grass'
    rod_type = params[:rod_type]

    # Check if trainer has adventures remaining
    unless @trainer.has_adventures?
      redirect_to catches_path, alert: "You're out of adventures! Visit the Poké Center to replenish."
      return
    end

    # Use one adventure
    unless @trainer.use_adventure
      redirect_to catches_path, alert: "Unable to use adventure. Please try again."
      return
    end

    # Store adventure parameters in session for "Adventure Again"
    session[:last_adventure] = {
      'route_id' => route.id,
      'encounter_type' => encounter_type,
      'rod_type' => rod_type
    }

    # Validate trainer has the exact rod they're trying to use
    if rod_type.present?
      has_rod = @trainer.has_item?(rod_type.to_sym)

      unless has_rod
        redirect_to catches_path, notice: "No Pokémon available on this route!"
        return
      end
    end

    # Pre-load trainer data to avoid N+1 queries
    captured_pokemon_ids = @trainer.captures.pluck(:pokemon_id).to_set
    unlocked_gate_numbers = @trainer.gate_unlocks.joins(:gate).pluck('gates.gate_number').to_set
    trainer_items = @trainer.trainer_items.joins(:item).pluck('items.key', :quantity).to_h

    # Get all Pokemon on this route that meet appearance requirements (including already caught)
    # Filter by encounter type
    available_encounters = route.route_encounters.select do |encounter|
      next false unless encounter_available_optimized?(encounter, captured_pokemon_ids, unlocked_gate_numbers, trainer_items)
      next false unless encounter.encounter_type == encounter_type

      # For fish encounters, filter by rod type if specified
      if encounter_type == 'fish' && rod_type.present?
        # Exclusive rod selection: each rod uses only its own encounter table
        encounter.required_item_key == rod_type
      else
        true
      end
    end

    if available_encounters.empty?
      redirect_to catches_path, notice: "No Pokémon available on this route!"
      return
    end

    # Calculate total weight from available encounters
    total_weight = available_encounters.sum(&:spawn_rate)
    random_value = rand(1..total_weight)

    # Find which Pokemon was encountered
    cumulative_weight = 0
    encountered_pokemon = nil
    available_encounters.each do |encounter|
      cumulative_weight += encounter.spawn_rate
      if random_value <= cumulative_weight
        encountered_pokemon = encounter.pokemon
        break
      end
    end

    # Store the encountered Pokemon ID in session to prevent URL manipulation
    session[:current_encounter] = encountered_pokemon.id

    # Redirect to the encounter page for this Pokemon
    redirect_to catch_path(encountered_pokemon)
  end

  def show
    @trainer = current_trainer
    @pokemon = Pokemon.find(params[:id])

    # Set encounter session if not already set (for direct access compatibility)
    session[:current_encounter] ||= params[:id].to_i

    # Check if already caught
    @already_caught = @trainer.captured_pokemon.include?(@pokemon)

    # Get catch probabilities for each ball type
    @catch_probabilities = PokemonCatchService::CAPTURE_EFFICIENCY.transform_values do |difficulty_hash|
      difficulty_hash[@pokemon.difficulty]
    end

    # Get last adventure parameters for "Adventure Again" button
    @last_adventure = session[:last_adventure]

    # Check if trainer has any pokeballs (show message but don't redirect)
    # Only show this message if there isn't already a flash message
    if @trainer.total_pokeballs == 0 && flash[:alert].nil?
      flash.now[:alert] = "You don't have any Pokéballs! Complete tickets to earn some."
    end
  end

  def create
    @trainer = current_trainer
    @pokemon = Pokemon.find(params[:id])

    # Validate this is the current encounter (prevent URL manipulation)
    if session[:current_encounter] && params[:id].to_i != session[:current_encounter]
      redirect_to catches_path, alert: "That's cheating. Please start a new adventure."
      return
    end
    # If no session exists, set it (for test compatibility and edge cases)
    session[:current_encounter] ||= params[:id].to_i

    ball_type = params[:ball_type]

    result = PokemonCatchService.new(@trainer, ball_type, @pokemon).catch!

    if result[:success]
      if result[:caught]
        # Clear the current encounter from session
        session.delete(:current_encounter)

        if result[:duplicate]
          # Duplicate capture - gave Evolution Stone
          message = "Success! You caught #{@pokemon.name} (##{@pokemon.pokedex_number}) with a #{result[:ball_type].humanize}! Since #{@pokemon.name} is already in your Pokédex, you received an Evolution Stone!"
          redirect_to pokedex_path, notice: message
        else
          # New capture
          # Check if trainer has now caught all 151 Pokemon (distinct)
          distinct_pokemon_count = @trainer.captures.select(:pokemon_id).distinct.count

          if distinct_pokemon_count >= 151
            # Trainer completed the Pokedex! Offer Elite Trainer status
            redirect_to elite_trainer_congratulations_path and return
          end

          # Auto-unlock gates after catching (difficulty score increased)
          newly_unlocked = @trainer.auto_unlock_gates!

          # If gates were unlocked, redirect to celebration page
          if newly_unlocked.any?
            # Store the first unlocked gate in session for celebration page
            session[:newly_unlocked_gate_id] = newly_unlocked.first.id
            redirect_to gates_celebration_path and return
          end

          # Build success message
          message = "Success! You caught #{@pokemon.name} (##{@pokemon.pokedex_number}) with a #{result[:ball_type].humanize}!"
          redirect_to pokedex_path, notice: message
        end
      else
        # Pokemon broke free
        # Check if trainer has any balls remaining
        if @trainer.total_pokeballs > 0
          # Trainer still has balls, stay on the encounter page to try again
          redirect_to catch_path(@pokemon), alert: result[:message]
        else
          # Trainer is out of all balls, redirect to route selection
          redirect_to catches_path, alert: result[:message]
        end
      end
    else
      # Error occurred (no balls, etc.)
      redirect_to catch_path(@pokemon), alert: result[:error]
    end
  end

  def run
    # Validate this is the current encounter (prevent URL manipulation)
    if session[:current_encounter] && params[:id].to_i != session[:current_encounter]
      redirect_to catches_path, alert: "That's cheating. Please start a new adventure."
      return
    end

    # Clear the current encounter from session
    session.delete(:current_encounter)

    redirect_to catches_path, notice: "Got Away Safely"
  end

  def visit_poke_center
    @trainer = current_trainer
    result = @trainer.claim_adventures

    if result[:claimed] > 0
      redirect_to catches_path, notice: "Welcome to the Poké Center! Restored +#{result[:claimed]} adventure#{'s' if result[:claimed] != 1}. (#{result[:new_total]}/10)"
    else
      redirect_to catches_path, alert: "No adventures available to claim yet. Next adventure in #{@trainer.formatted_time_until_adventure}."
    end
  end

  def use_potion
    @trainer = current_trainer
    potion_key = params[:potion_key]

    result = @trainer.use_potion(potion_key)

    if result[:success]
      redirect_to catches_path, notice: "Used #{result[:potion_name]}! Restored +#{result[:restored]} adventure#{'s' if result[:restored] != 1}. (#{result[:new_total]}/10)"
    else
      redirect_to catches_path, alert: result[:error]
    end
  end

  private

  # Optimized version of RouteEncounter#available_for? that uses pre-loaded data
  # to avoid N+1 queries when checking many encounters
  def encounter_available_optimized?(encounter, captured_pokemon_ids, unlocked_gate_numbers, trainer_items)
    # Check Pokemon requirement (OR logic if alternative exists)
    if encounter.required_pokemon_id.present?
      has_required = captured_pokemon_ids.include?(encounter.required_pokemon_id)

      if encounter.alternative_required_pokemon_id.present?
        has_alternative = captured_pokemon_ids.include?(encounter.alternative_required_pokemon_id)
        return false unless (has_required || has_alternative)
      else
        return false unless has_required
      end
    end

    # Check gate requirement
    if encounter.required_gate_number.present?
      return false unless unlocked_gate_numbers.include?(encounter.required_gate_number)
    end

    # Check item requirement (for fishing rods, etc.)
    if encounter.required_item_key.present?
      case encounter.required_item_key
      when 'old_rod'
        return false unless (trainer_items['old_rod'] || 0) > 0 || (trainer_items['good_rod'] || 0) > 0 || (trainer_items['super_rod'] || 0) > 0
      when 'good_rod'
        return false unless (trainer_items['good_rod'] || 0) > 0 || (trainer_items['super_rod'] || 0) > 0
      when 'super_rod'
        return false unless (trainer_items['super_rod'] || 0) > 0
      else
        # For other items (like hm_surf), require exact match
        return false unless (trainer_items[encounter.required_item_key] || 0) > 0
      end
    end

    true
  end
end
