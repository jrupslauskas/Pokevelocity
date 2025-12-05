class Gate < ApplicationRecord
  has_many :gate_unlocks, dependent: :destroy
  has_many :trainers, through: :gate_unlocks
  has_many :routes, foreign_key: :gate_requirement, primary_key: :gate_number

  validates :gate_number, presence: true, uniqueness: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 8 }
  validates :required_difficulty_score, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Load YAML data - reloads in development for easy editing
  def self.gates_data
    if Rails.env.development?
      YAML.load_file(Rails.root.join("db", "data", "gates.yml"))
    else
      @gates_data ||= YAML.load_file(Rails.root.join("db", "data", "gates.yml")).freeze
    end
  end

  def self.data_for(gate_number)
    gates_data.find { |g| g["gate_number"] == gate_number }
  end

  # Load display data from YAML at runtime
  def gate_data
    if Rails.env.development?
      self.class.data_for(gate_number)
    else
      @gate_data ||= self.class.data_for(gate_number)
    end
  end

  # Override attribute readers to pull from YAML instead of database
  def name
    gate_data&.dig("name") || "Gate #{gate_number}"
  end

  def description
    gate_data&.dig("description") || ""
  end

  def sprite_type
    gate_data&.dig("sprite_type") || "emoji"
  end

  def sprite_value
    gate_data&.dig("sprite_value") || "🚪"
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
