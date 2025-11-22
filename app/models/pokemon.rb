class Pokemon < ApplicationRecord
  has_one_attached :image

  has_many :captures, dependent: :destroy
  has_many :trainers, through: :captures

  has_many :route_encounters, dependent: :destroy
  has_many :routes, through: :route_encounters

  validates :pokedex_number, presence: true, uniqueness: true,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 151 }
  validates :name, presence: true
  validates :difficulty, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }

  # Load Pokemon data from YAML file for use throughout the application
  POKEDEX_DATA = YAML.load_file(Rails.root.join("db", "data", "pokemon.yml")).freeze

  # Helper method to find Pokemon data by pokedex number
  def self.data_for(pokedex_number)
    POKEDEX_DATA.find { |p| p["pokedex_number"] == pokedex_number }
  end

  # Helper method to find Pokemon data by name
  def self.data_by_name(name)
    POKEDEX_DATA.find { |p| p["name"] == name }
  end
end
