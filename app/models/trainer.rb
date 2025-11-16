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

  private

  def password_required?
    password_digest.blank? || password.present?
  end
end
