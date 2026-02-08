class TrainersController < ApplicationController
  before_action :require_login, only: [ :dashboard, :discard_item, :pokedex, :evolution_lab, :evolve ]

  def new
    @trainer = Trainer.new
    @pokemon = Pokemon.order(:pokedex_number)
    @trainer_sprites = get_trainer_sprites
  end

  def create
    @trainer = Trainer.new(trainer_params)
    @pokemon = Pokemon.order(:pokedex_number)
    @trainer_sprites = get_trainer_sprites

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
      redirect_to onboarding_welcome_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def dashboard
    @trainer = current_trainer

    # Fetch items with quantity > 0, organized by type
    @pokeball_items = fetch_items_by_type("pokeball")
    @evolution_items = fetch_items_by_type("evolution_stone")
    @restoration_items = fetch_items_by_type("potion")
    @adventure_items = fetch_items_by_type("key_item")

    # Fetch news feed: recent captures and evolutions from other trainers
    @news_feed = build_news_feed
  end

  def discard_item
    @trainer = current_trainer
    item_key = params[:item_key]

    # Find the item
    item = Item.find_by(key: item_key)

    unless item
      redirect_to dashboard_path, alert: "Item not found."
      return
    end

    # Only allow discarding pokeballs, evolution stones, and potions
    unless item.pokeball? || item.evolution_stone? || item.potion?
      redirect_to dashboard_path, alert: "You cannot discard this item."
      return
    end

    # Find the trainer's item
    trainer_item = @trainer.trainer_items.find_by(item: item)

    unless trainer_item && trainer_item.quantity > 0
      redirect_to dashboard_path, alert: "You don't have any #{item.name} to discard."
      return
    end

    # Decrement quantity by 1
    if trainer_item.quantity > 1
      trainer_item.update!(quantity: trainer_item.quantity - 1)
    else
      # If quantity is 1, remove the item entirely
      trainer_item.destroy!
    end

    redirect_to dashboard_path, notice: "Discarded 1 #{item.name}."
  end

  def pokedex
    @trainer = current_trainer
    @captured_pokemon = @trainer.captured_pokemon.order(:pokedex_number)
    @total_trainers = Trainer.count

    # Calculate how many trainers have caught each Pokémon
    # Build a hash: { pokemon_id => count_of_trainers }
    @pokemon_trainer_counts = Capture.where(pokemon_id: @captured_pokemon.pluck(:id))
                                     .select(:pokemon_id)
                                     .group(:pokemon_id)
                                     .distinct
                                     .count("DISTINCT trainer_id")

    # Load party members for display (positions 1-6)
    @party_members = @trainer.party_members.includes(:pokemon).order(:position)
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
      ball_type: original_capture&.ball_type || "pokeball",
      captured_at: Time.current,
      evolved: true
    )

    # Auto-unlock gates after evolution (difficulty score increased)
    newly_unlocked = @trainer.auto_unlock_gates!

    # Store celebration data in session (always show Pokemon celebration first)
    session[:pokemon_celebration] = {
      pokemon_id: evolution.to_pokemon_id,
      event_type: 'evolved',
      from_pokemon_name: evolution.from_pokemon.name
    }

    # If gates were unlocked, store for follow-up celebration
    if newly_unlocked.any?
      session[:newly_unlocked_gate_id] = newly_unlocked.first.id
    end

    redirect_to pokemon_celebration_path
  end

  private

  def trainer_params
    params.require(:trainer).permit(:username, :password, :icon_pokemon_id, :icon_trainer_sprite)
  end

  # Get list of available trainer sprites, sorted alphabetically
  def get_trainer_sprites
    regular_trainers = [
      "aroma-lady", "beauty", "biker", "bill", "bird-keeper", "black-belt",
      "blue-casual", "blue-faceoff", "bug-catcher", "burglar", "camper",
      "channeler", "cool-couple", "cooltrainer-female", "cooltrainer-male", "crush-girl",
      "crush-kin", "cue-ball", "daisy-oak", "engineer", "fisherman",
      "gentleman", "hiker", "juggler", "lady",
      "lass", "mr-fuji", "painter", "picnicker", "pokemaniac", "pokemon-breeder",
      "pokemon-ranger-female", "pokemon-ranger-male", "psychic-female", "psychic-male",
      "red-portrait", "rocker", "rocker-grunt-female", "rocker-grunt-male", "ruin-maniac",
      "sailor", "scientist", "sis-and-bro", "super-nerd", "swimmer-female", "swimmer-male",
      "tamer", "tuber", "twins", "young-couple", "youngster"
    ]

    gym_leaders = [
      "gymLeaders/agatha", "gymLeaders/blaine", "gymLeaders/blue", "gymLeaders/brock", "gymLeaders/bruno",
      "gymLeaders/erika", "gymLeaders/giovanni", "gymLeaders/koga", "gymLeaders/lance", "gymLeaders/lorelei",
      "gymLeaders/ltsurge", "gymLeaders/misty", "gymLeaders/oak", "gymLeaders/red", "gymLeaders/sabrina"
    ]

    # Sort alphabetically by display name (last part after '/')
    (regular_trainers + gym_leaders).sort_by { |sprite| sprite.split("/").last }
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
    if types.include?("pokeball")
      pokeball_order = [ "pokeball", "great_ball", "ultra_ball", "master_ball" ]
      items.sort_by { |item_data| pokeball_order.index(item_data[:item].key) || Float::INFINITY }
    else
      items
    end
  end

  # Build news feed of recent captures and evolutions from all trainers (including current trainer)
  # @return [Array<Hash>] array of event hashes with :type, :trainer, :pokemon, :timestamp
  def build_news_feed
    # Get recent captures (non-evolved) from all trainers
    recent_catches = Capture.includes(:trainer, :pokemon)
                            .where(evolved: false)
                            .order(created_at: :desc)
                            .limit(25)
                            .map { |c| {
                              type: "caught",
                              trainer: c.trainer,
                              pokemon: c.pokemon,
                              timestamp: c.created_at,
                              ball_type: c.ball_type
                            }}

    # Get recent evolutions from all trainers
    recent_evolutions = Capture.includes(:trainer, :pokemon)
                               .where(evolved: true)
                               .order(created_at: :desc)
                               .limit(25)
                               .map { |c| {
                                 type: "evolved",
                                 trainer: c.trainer,
                                 pokemon: c.pokemon,
                                 timestamp: c.created_at,
                                 ball_type: c.ball_type
                               }}

    # Merge and sort by timestamp, then take top 50
    (recent_catches + recent_evolutions)
      .sort_by { |event| event[:timestamp] }
      .reverse
      .take(50)
  end
end
