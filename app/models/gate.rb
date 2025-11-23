class Gate < ApplicationRecord
  has_many :gate_unlocks, dependent: :destroy
  has_many :trainers, through: :gate_unlocks
  has_many :routes, foreign_key: :gate_requirement, primary_key: :gate_number

  validates :gate_number, presence: true, uniqueness: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 8 }
  validates :name, presence: true
  validates :required_difficulty_score, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  GATES_DATA = YAML.load_file(Rails.root.join("db", "data", "gates.yml")).freeze

  def self.data_for(gate_number)
    GATES_DATA.find { |g| g["gate_number"] == gate_number }
  end

  # Check if this gate is unlocked for a specific trainer
  def unlocked_for?(trainer)
    trainer.gate_unlocks.exists?(gate_id: id)
  end

  # Check if trainer meets the difficulty score requirement
  def requirement_met_for?(trainer)
    trainer.difficulty_score >= required_difficulty_score
  end
end
