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

    # Get all gates ordered by gate number
    @gates = Gate.order(:gate_number).includes(:routes)

    # Get next locked gate to show only routes up to that gate
    @next_locked_gate = @trainer.next_locked_gate

    # Get routes that don't require any gate (null gate_requirement) - always accessible
    @always_accessible_routes = Route.where(gate_requirement: nil)
                                     .order(:order)
                                     .includes(route_encounters: :pokemon)

    # Get accessible routes based on unlocked gates (only up to next locked gate)
    if @next_locked_gate
      # Show routes up to (but not including) the next locked gate
      accessible_gate_numbers = @trainer.unlocked_gates.pluck(:gate_number)
      @gated_routes = Route.where(gate_requirement: accessible_gate_numbers)
                           .order(:order)
                           .includes(route_encounters: :pokemon)
    else
      # All gates unlocked, show all gated routes
      @gated_routes = Route.where.not(gate_requirement: nil)
                           .order(:order)
                           .includes(route_encounters: :pokemon)
    end

    # For each route, show all Pokemon (including already caught)
    @route_available_pokemon = {}
    (@always_accessible_routes + @gated_routes).each do |route|
      @route_available_pokemon[route.id] = route.pokemon
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

    # Get all Pokemon on this route (including already caught)
    available_encounters = route.route_encounters

    if available_encounters.empty?
      redirect_to catches_path, notice: "No Pokémon on this route!"
      return
    end

    # Calculate total weight from all encounters
    total_weight = available_encounters.sum(:spawn_rate)
    random_value = rand(1..total_weight)

    # Find which Pokemon was encountered
    cumulative_weight = 0
    encountered_pokemon = nil
    available_encounters.includes(:pokemon).each do |encounter|
      cumulative_weight += encounter.spawn_rate
      if random_value <= cumulative_weight
        encountered_pokemon = encounter.pokemon
        break
      end
    end

    # Redirect to the encounter page for this Pokemon
    redirect_to catch_path(encountered_pokemon)
  end

  def show
    @trainer = current_trainer
    @pokemon = Pokemon.find(params[:id])

    # Check if already caught
    @already_caught = @trainer.captured_pokemon.include?(@pokemon)

    # Get catch probabilities for each ball type
    @catch_probabilities = PokemonCatchService::CAPTURE_EFFICIENCY.transform_values do |difficulty_hash|
      difficulty_hash[@pokemon.difficulty]
    end

    # Check if trainer has any pokeballs (show message but don't redirect)
    # Only show this message if there isn't already a flash message
    if @trainer.total_pokeballs == 0 && flash[:alert].nil?
      flash.now[:alert] = "You don't have any Pokéballs! Complete tickets to earn some."
    end
  end

  def create
    @trainer = current_trainer
    @pokemon = Pokemon.find(params[:id])
    ball_type = params[:ball_type]

    result = PokemonCatchService.new(@trainer, ball_type, @pokemon).catch!

    if result[:success]
      if result[:caught]
        if result[:duplicate]
          # Duplicate capture - gave Evolution Stone
          message = "Success! You caught #{@pokemon.name} (##{@pokemon.pokedex_number}) with a #{result[:ball_type].humanize}! Since #{@pokemon.name} is already in your Pokédex, you received an Evolution Stone!"
          redirect_to pokedex_path, notice: message
        else
          # New capture
          # Auto-unlock gates after catching (difficulty score increased)
          newly_unlocked = @trainer.auto_unlock_gates!

          # Build success message
          message = "Success! You caught #{@pokemon.name} (##{@pokemon.pokedex_number}) with a #{result[:ball_type].humanize}!"
          if newly_unlocked.any?
            message += " You unlocked #{newly_unlocked.map(&:name).join(', ')}!"
          end

          redirect_to pokedex_path, notice: message
        end
      else
        # Pokemon broke free
        redirect_to catches_path, alert: result[:message]
      end
    else
      # Error occurred (no balls, etc.)
      redirect_to catch_path(@pokemon), alert: result[:error]
    end
  end

  def run
    redirect_to catches_path, notice: "Got Away Safely"
  end
end
