class Capture < ApplicationRecord
  BALL_TYPES = %w[pokeball great_ball ultra_ball master_ball].freeze

  belongs_to :trainer
  belongs_to :pokemon

  validates :ball_type, presence: true, inclusion: { in: BALL_TYPES }
  validates :captured_at, presence: true
  validates :pokemon_id, uniqueness: { scope: :trainer_id, message: "has already been captured by this trainer" }

  before_validation :set_captured_at, on: :create

  private

  def set_captured_at
    self.captured_at ||= Time.current
  end
end
