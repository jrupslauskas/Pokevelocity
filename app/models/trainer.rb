class Trainer < ApplicationRecord
  has_secure_password

  has_many :captures, dependent: :destroy
  has_many :captured_pokemon, through: :captures, source: :pokemon
  belongs_to :icon_pokemon, class_name: "Pokemon", optional: true
  has_many :gate_unlocks, dependent: :destroy
  has_many :unlocked_gates, through: :gate_unlocks, source: :gate

  validates :username, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 1 }, if: :password_required?
  validates :pokeballs_count, :great_balls_count, :ultra_balls_count, :master_balls_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Award a pokeball based on story points completed
  def award_pokeball_for_ticket(story_points)
    PokeballRewardService.new(self, story_points).award!
  end

  # Get total number of all pokeballs
  def total_pokeballs
    pokeballs_count + great_balls_count + ultra_balls_count + master_balls_count
  end

  # Get the count for a specific ball type
  # @param ball_type [String] "pokeball", "great_ball", "ultra_ball", or "master_ball"
  # @return [Integer] the count of that ball type
  def ball_count(ball_type)
    send("#{ball_type}s_count")
  end

  # Check if trainer has at least one ball of the given type
  # @param ball_type [String] "pokeball", "great_ball", "ultra_ball", or "master_ball"
  # @return [Boolean] true if count > 0
  def has_ball?(ball_type)
    ball_count(ball_type) > 0
  end

  # Deduct one ball of the given type and save
  # @param ball_type [String] "pokeball", "great_ball", "ultra_ball", or "master_ball"
  def deduct_ball!(ball_type)
    decrement!("#{ball_type}s_count", 1)
  end

  # Add one ball of the given type and save
  # @param ball_type [String] "pokeball", "great_ball", "ultra_ball", or "master_ball"
  def add_ball!(ball_type)
    increment!("#{ball_type}s_count", 1)
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
    {
      trainer: self,
      pokemon_count: captured_pokemon.count,
      difficulty_score: difficulty_score
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

    gate_unlocks.create!(gate: gate, unlocked_at: Time.current)
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

  private

  def password_required?
    password_digest.blank? || password.present?
  end
end
