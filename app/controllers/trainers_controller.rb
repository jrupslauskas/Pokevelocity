class TrainersController < ApplicationController
  before_action :require_login, only: [:dashboard, :pokedex]

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
