class Trainer < ApplicationRecord
  has_secure_password

  has_many :captures, dependent: :destroy
  has_many :captured_pokemon, through: :captures, source: :pokemon
  belongs_to :icon_pokemon, class_name: "Pokemon", optional: true

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

  private

  def password_required?
    password_digest.blank? || password.present?
  end
end
