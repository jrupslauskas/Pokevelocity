class Trainer < ApplicationRecord
  has_secure_password

  has_many :captures, dependent: :destroy
  has_many :captured_pokemon, through: :captures, source: :pokemon
  belongs_to :icon_pokemon, class_name: "Pokemon", optional: true
  has_many :gate_unlocks, dependent: :destroy
  has_many :unlocked_gates, through: :gate_unlocks, source: :gate
  has_many :trainer_items, dependent: :destroy
  has_many :items, through: :trainer_items
  has_many :party_members, -> { order(:position) }, dependent: :destroy
  has_many :party_pokemon, through: :party_members, source: :pokemon

  validates :username, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 1 }, if: :password_required?
  validate :icon_selection_present, on: :create

  def icon_selection_present
    if icon_pokemon_id.blank? && icon_trainer_sprite.blank?
      errors.add(:base, "Please select an icon (Pokémon or Trainer)")
    elsif icon_pokemon_id.present? && icon_trainer_sprite.present?
      errors.add(:base, "Please select only one icon (either Pokémon or Trainer, not both)")
    end
  end

  # Award a pokeball based on story points completed
  def award_pokeball_for_ticket(story_points)
    PokeballRewardService.new(self, story_points).award!
  end

  # ================================================================================
  # POKEBALL MANAGEMENT (via items system)
  # ================================================================================

  # Get total number of all pokeballs
  def total_pokeballs
    item_quantity(:pokeball) + item_quantity(:great_ball) +
    item_quantity(:ultra_ball) + item_quantity(:master_ball)
  end

  # Get the count for a specific ball type
  # @param ball_type [String, Symbol] :pokeball, :great_ball, :ultra_ball, or :master_ball
  # @return [Integer] the count of that ball type
  def ball_count(ball_type)
    item_quantity(ball_type)
  end

  # Check if trainer has at least one ball of the given type
  # @param ball_type [String, Symbol] :pokeball, :great_ball, :ultra_ball, or :master_ball
  # @return [Boolean] true if count > 0
  def has_ball?(ball_type)
    has_item?(ball_type, 1)
  end

  # Deduct one ball of the given type and save
  # @param ball_type [String, Symbol] :pokeball, :great_ball, :ultra_ball, or :master_ball
  def deduct_ball!(ball_type)
    remove_item(ball_type, 1)
  end

  # Add one ball of the given type and save
  # @param ball_type [String, Symbol] :pokeball, :great_ball, :ultra_ball, or :master_ball
  def add_ball!(ball_type)
    add_item(ball_type, 1)
  end

  # Calculate the difficulty score for leaderboard ranking
  # This is the sum of all difficulty values of captured pokemon
  # @return [Integer] total difficulty score
  def difficulty_score
    captured_pokemon.sum(:difficulty)
  end

  # Get the leaderboard score hash for this trainer
  # @return [Hash] containing trainer, pokemon_count, and difficulty_score
  def leaderboard_score
    # Calculate total score including Elite Trainer bonus
    # Formula: Current Difficulty + (377 × Elite Trainer Level)
    elite_bonus = elite_trainer_level * 377
    total_score = difficulty_score + elite_bonus

    {
      trainer: self,
      pokemon_count: captured_pokemon.count,
      difficulty_score: total_score
    }
  end

  # Check if trainer has unlocked a specific gate
  # @param gate [Gate] the gate to check
  # @return [Boolean] true if unlocked
  def has_unlocked_gate?(gate)
    unlocked_gates.exists?(id: gate.id)
  end

  # Unlock a gate for this trainer if they meet the requirement
  # @param gate [Gate] the gate to unlock
  # @return [GateUnlock, nil] the unlock record or nil if requirement not met
  def unlock_gate!(gate)
    return nil if has_unlocked_gate?(gate)
    return nil unless gate.requirement_met_for?(self)

    gate_unlock = gate_unlocks.create!(gate: gate, unlocked_at: Time.current)

    # Award HM03 Surf for defeating Koga (Gate 5)
    if gate.gate_number == 5 && !has_item?(:hm_surf)
      add_item(:hm_surf, 1)
    end

    gate_unlock
  end

  # Get the next locked gate that meets or doesn't meet the requirement
  # @return [Gate, nil] the next gate or nil if all unlocked
  def next_locked_gate
    Gate.order(:gate_number).find do |gate|
      !has_unlocked_gate?(gate)
    end
  end

  # Auto-unlock all gates that meet the difficulty score requirement
  # @return [Array<Gate>] array of newly unlocked gates
  def auto_unlock_gates!
    newly_unlocked = []
    Gate.order(:gate_number).each do |gate|
      next if has_unlocked_gate?(gate)
      unlock = unlock_gate!(gate)
      newly_unlocked << gate if unlock
    end
    newly_unlocked
  end

  # Get all routes that are accessible to this trainer (based on unlocked gates)
  # @return [ActiveRecord::Relation<Route>] accessible routes
  def accessible_routes
    unlocked_gate_numbers = unlocked_gates.pluck(:gate_number)
    Route.where(gate_requirement: unlocked_gate_numbers).order(:order)
  end

  # ================================================================================
  # ITEM MANAGEMENT
  # ================================================================================

  # Get quantity of a specific item by key
  # @param item_key [String, Symbol] the item key (e.g., :fire_stone)
  # @return [Integer] quantity of the item
  def item_quantity(item_key)
    item = Item.find_by(key: item_key.to_s)
    return 0 unless item

    trainer_item = trainer_items.find_by(item: item)
    trainer_item&.quantity || 0
  end

  # Add an item to the trainer's inventory
  # @param item_key [String, Symbol] the item key
  # @param quantity [Integer] amount to add (default: 1)
  def add_item(item_key, quantity = 1)
    item = Item.find_by(key: item_key.to_s)
    return false unless item

    trainer_item = trainer_items.find_or_initialize_by(item: item)
    trainer_item.quantity ||= 0
    trainer_item.quantity += quantity
    trainer_item.save
  end

  # Remove an item from the trainer's inventory
  # @param item_key [String, Symbol] the item key
  # @param quantity [Integer] amount to remove (default: 1)
  # @return [Boolean] true if successful, false if not enough items
  def remove_item(item_key, quantity = 1)
    item = Item.find_by(key: item_key.to_s)
    return false unless item

    trainer_item = trainer_items.find_by(item: item)
    return false unless trainer_item && trainer_item.quantity >= quantity

    trainer_item.remove(quantity)
  end

  # Check if trainer has at least a certain quantity of an item
  # @param item_key [String, Symbol] the item key
  # @param quantity [Integer] minimum quantity to check (default: 1)
  # @return [Boolean] true if trainer has enough
  def has_item?(item_key, quantity = 1)
    item_quantity(item_key) >= quantity
  end

  # ================================================================================
  # ADVENTURE MANAGEMENT
  # ================================================================================

  # Calculate how many pokecenter credits are available
  # Credits accumulate at 1 per day, capped at 2 total
  # @return [Integer] number of credits available (0-2)
  def available_pokecenter_credits
    # First time visitor - give them 1 free credit
    return 1 if adventures_allocated_at.nil?

    # Current banked credits
    current_credits = pokecenter_credits

    # Already at max
    return 2 if current_credits >= 2

    # Calculate days elapsed since last visit
    last_visit_date = adventures_allocated_at.to_date
    today = Date.current
    days_elapsed = (today - last_visit_date).to_i

    # Award 1 credit per day, cap at 2 total
    [current_credits + days_elapsed, 2].min
  end

  # Visit Poké Center - uses 1 credit to restore 5 adventures
  # @return [Hash] result with :success, :restored, :new_total, :credits_remaining
  def claim_adventures
    available_credits = available_pokecenter_credits

    # No credits available
    if available_credits == 0
      return {
        success: false,
        restored: 0,
        new_total: adventures_remaining,
        credits_remaining: 0
      }
    end

    # Use 1 credit, restore 5 adventures
    old_count = adventures_remaining
    new_count = [adventures_remaining + 5, 10].min
    actual_restored = new_count - old_count

    # Update: decrement credits, restore adventures, update timestamp
    update!(
      pokecenter_credits: available_credits - 1,
      adventures_remaining: new_count,
      adventures_allocated_at: Time.current
    )

    {
      success: true,
      restored: actual_restored,
      new_total: new_count,
      credits_remaining: available_credits - 1
    }
  end

  # Use one adventure (decrement counter)
  # @return [Boolean] true if adventure was used, false if none remaining
  def use_adventure
    return false unless has_adventures?
    decrement!(:adventures_remaining)
    true
  end

  # Use a potion to restore adventures
  # @param potion_key [Symbol] the key of the potion item (:potion, :super_potion, :hyper_potion)
  # @return [Hash] result with :success, :restored, :new_total, :error
  def use_potion(potion_key)
    item = Item.find_by(key: potion_key.to_s)

    # Validate item exists and is a potion
    if item.nil?
      return { success: false, error: "Item not found" }
    end

    unless item.potion?
      return { success: false, error: "This item is not a potion" }
    end

    # Check if trainer has the potion
    unless has_item?(potion_key, 1)
      return { success: false, error: "You don't have any #{item.name}" }
    end

    # Already at max adventures
    if adventures_remaining >= 10
      return { success: false, error: "You already have maximum adventures" }
    end

    # Get restoration amount
    restore_amount = item.adventure_restore
    old_count = adventures_remaining
    new_count = [ adventures_remaining + restore_amount, 10 ].min
    actual_restored = new_count - old_count

    # Initialize timestamp if needed
    if adventures_allocated_at.nil?
      update!(adventures_allocated_at: Time.current)
    end

    # Restore adventures and consume potion
    update!(adventures_remaining: new_count)
    remove_item(potion_key, 1)

    {
      success: true,
      restored: actual_restored,
      new_total: new_count,
      potion_name: item.name
    }
  end

  # Check if trainer has adventures remaining
  # @return [Boolean] true if adventures_remaining > 0
  def has_adventures?
    adventures_remaining > 0
  end

  # Get the time remaining until next adventure is available to claim
  # @return [Integer] seconds until midnight (0 if already claimable or never visited)
  def time_until_next_adventure
    return 0 if adventures_allocated_at.nil?

    # Check if already claimable (last visit was not today)
    last_visit_date = adventures_allocated_at.to_date
    today = Date.current
    return 0 if last_visit_date != today

    # Calculate time until midnight (start of next day in configured timezone)
    tomorrow_start = Time.zone.now.beginning_of_day + 1.day
    seconds = (tomorrow_start - Time.current).to_i
    seconds > 0 ? seconds : 0
  end

  # Format time until next adventure as a human-readable string
  # @return [String] formatted time (e.g., "5h 23m", "45m", "2s")
  def formatted_time_until_adventure
    seconds = time_until_next_adventure
    return "now" if seconds <= 0

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    remaining_seconds = seconds % 60

    if hours > 0
      "#{hours}h #{minutes}m"
    elsif minutes > 0
      "#{minutes}m"
    else
      "#{remaining_seconds}s"
    end
  end

  # ================================================================================
  # ONBOARDING
  # ================================================================================

  # Check if trainer needs to complete onboarding
  # @return [Boolean] true if onboarding not completed
  def needs_onboarding?
    !onboarding_completed
  end

  # Mark onboarding as completed
  # @return [Boolean] true if successful
  def complete_onboarding!
    update!(onboarding_completed: true)
  end

  private

  def password_required?
    password_digest.blank? || password.present?
  end
end
