class Route < ApplicationRecord
  has_many :route_encounters, dependent: :destroy
  has_many :pokemon, through: :route_encounters
  belongs_to :required_gate, class_name: "Gate", foreign_key: :gate_requirement, primary_key: :gate_number, optional: true

  validates :name, presence: true, uniqueness: true
  validates :gate_requirement,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 8, allow_nil: true }
  validates :order, presence: true, uniqueness: true,
            numericality: { only_integer: true, greater_than: 0 }

  # Load routes data from YAML file for use throughout the application
  ROUTES_DATA = YAML.load_file(Rails.root.join("db", "data", "routes.yml")).freeze

  # Helper method to find route data by name
  def self.data_for(route_name)
    ROUTES_DATA.find { |r| r["name"] == route_name }
  end

  # Select a random Pokemon from this route based on spawn rates
  def random_encounter
    return nil if route_encounters.empty?

    # Get all encounters with their spawn rates
    encounters = route_encounters.includes(:pokemon)
    total_weight = encounters.sum(:spawn_rate)

    # Random number between 1 and total weight
    random_value = rand(1..total_weight)

    # Find which Pokemon was selected
    cumulative_weight = 0
    encounters.each do |encounter|
      cumulative_weight += encounter.spawn_rate
      return encounter.pokemon if random_value <= cumulative_weight
    end

    # Fallback to first Pokemon (should never reach here)
    encounters.first.pokemon
  end
end
