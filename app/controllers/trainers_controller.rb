class TrainersController < ApplicationController
  before_action :require_login, only: [:dashboard, :pokedex, :evolution_lab, :evolve]

  def new
    @trainer = Trainer.new
    @pokemon = Pokemon.order(:pokedex_number)
  end

  def create
    @trainer = Trainer.new(trainer_params)
    @pokemon = Pokemon.order(:pokedex_number)

    # Validate activation code
    activation_code = params[:activation_code]&.strip&.upcase
    valid_code = ValidationCode.find_by(active: true)

    if valid_code.nil? || activation_code.blank? || activation_code != valid_code.code
      @trainer.errors.add(:base, "Invalid activation code")
      render :new, status: :unprocessable_entity
      return
    end

    if @trainer.save
      session[:trainer_id] = @trainer.id
      redirect_to dashboard_path, notice: "Welcome to Pokevelocity, #{@trainer.username}!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def dashboard
    @trainer = current_trainer

    # Fetch items with quantity > 0, organized by type
    @pokeball_items = fetch_items_by_type('pokeball')
    @evolution_items = fetch_items_by_type('evolution_stone')
    @adventure_items = fetch_items_by_type('potion', 'key_item')
  end

  def pokedex
    @trainer = current_trainer
    @captured_pokemon = @trainer.captured_pokemon.order(:pokedex_number)
  end

  def evolution_lab
    @trainer = current_trainer

    # Get all Pokemon the trainer has captured
    captured_pokemon = @trainer.captured_pokemon
    captured_pokemon_ids = captured_pokemon.pluck(:id)

    # Build list of available evolutions
    @available_evolutions = []

    captured_pokemon.each do |pokemon|
      # Get all possible evolutions for this Pokemon
      pokemon.evolutions_from.includes(:to_pokemon, :from_pokemon).each do |evolution|
        # Only show if trainer doesn't already have the evolved form
        unless captured_pokemon_ids.include?(evolution.to_pokemon_id)
          # Check if trainer has required items
          trainer_item = @trainer.trainer_items.joins(:item).find_by(items: { key: evolution.required_item_key })
          has_items = trainer_item && trainer_item.quantity >= evolution.required_item_quantity

          @available_evolutions << {
            evolution: evolution,
            from_pokemon: evolution.from_pokemon,
            to_pokemon: evolution.to_pokemon,
            required_item: evolution.required_item,
            required_quantity: evolution.required_item_quantity,
            trainer_has_items: has_items,
            trainer_item_quantity: trainer_item&.quantity || 0
          }
        end
      end
    end
  end

  def evolve
    @trainer = current_trainer
    evolution = Evolution.find(params[:id])

    # Verify trainer has the pre-evolution pokemon
    unless @trainer.captured_pokemon.exists?(id: evolution.from_pokemon_id)
      redirect_to evolution_lab_path, alert: "You don't have #{evolution.from_pokemon.name} in your Pokédex!"
      return
    end

    # Verify trainer doesn't already have the evolved form
    if @trainer.captured_pokemon.exists?(id: evolution.to_pokemon_id)
      redirect_to evolution_lab_path, alert: "You already have #{evolution.to_pokemon.name} in your Pokédex!"
      return
    end

    # Verify trainer has required items
    unless evolution.can_trainer_evolve?(@trainer)
      redirect_to evolution_lab_path, alert: "You don't have enough #{evolution.required_item.name} to evolve!"
      return
    end

    # Deduct the required items
    @trainer.remove_item(evolution.required_item_key, evolution.required_item_quantity)

    # Add the evolved Pokemon to the trainer's Pokedex
    # We'll use the same ball type as the original Pokemon was caught with
    original_capture = @trainer.captures.find_by(pokemon_id: evolution.from_pokemon_id)
    @trainer.captures.create!(
      pokemon_id: evolution.to_pokemon_id,
      ball_type: original_capture&.ball_type || 'pokeball',
      captured_at: Time.current
    )

    # Redirect to pokedex with success message
    redirect_to pokedex_path, notice: "Congratulations! Your #{evolution.from_pokemon.name} evolved into #{evolution.to_pokemon.name}!"
  end

  private

  def trainer_params
    params.require(:trainer).permit(:username, :password, :icon_pokemon_id)
  end

  # Fetch items of specific type(s) that the trainer has (quantity > 0)
  # @param types [String, Array<String>] one or more item types to fetch
  # @return [Array<Hash>] array of hashes with :item and :quantity
  def fetch_items_by_type(*types)
    items = @trainer.trainer_items
      .includes(:item)
      .with_quantity
      .select { |ti| types.include?(ti.item.item_type) }
      .map { |ti| { item: ti.item, quantity: ti.quantity } }

    # Sort pokeballs in specific order
    if types.include?('pokeball')
      pokeball_order = ['pokeball', 'great_ball', 'ultra_ball', 'master_ball']
      items.sort_by { |item_data| pokeball_order.index(item_data[:item].key) || Float::INFINITY }
    else
      items
    end
  end
end
