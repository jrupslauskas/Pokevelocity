class Item < ApplicationRecord
  has_many :trainer_items, dependent: :destroy
  has_many :trainers, through: :trainer_items

  validates :key, presence: true, uniqueness: true
  validates :item_type, presence: true, inclusion: { in: %w[pokeball evolution_stone potion key_item] }

  # Item types
  TYPES = {
    pokeball: 'pokeball',
    evolution_stone: 'evolution_stone',
    potion: 'potion',
    key_item: 'key_item'
  }.freeze

  # All items defined as constants
  ITEMS = {
    pokeball: {
      key: 'pokeball',
      name: 'Poké Ball',
      description: 'A device for catching wild Pokémon. It is designed as a capsule system.',
      item_type: TYPES[:pokeball],
      sprite: 'pokeball.png'
    },
    great_ball: {
      key: 'great_ball',
      name: 'Great Ball',
      description: 'A good, high-performance Poké Ball that provides a higher Pokémon catch rate than a standard Poké Ball.',
      item_type: TYPES[:pokeball],
      sprite: 'great_ball.png'
    },
    ultra_ball: {
      key: 'ultra_ball',
      name: 'Ultra Ball',
      description: 'An ultra-high performance Poké Ball that provides a higher success rate for catching Pokémon than a Great Ball.',
      item_type: TYPES[:pokeball],
      sprite: 'ultra_ball.png'
    },
    master_ball: {
      key: 'master_ball',
      name: 'Master Ball',
      description: 'The best Poké Ball with the ultimate level of performance. It will catch any wild Pokémon without fail.',
      item_type: TYPES[:pokeball],
      sprite: 'master_ball.png'
    },
    fire_stone: {
      key: 'fire_stone',
      name: 'Fire Stone',
      description: 'A peculiar stone that makes certain species of Pokémon evolve. It burns as red as the evening sun.',
      item_type: TYPES[:evolution_stone],
      sprite: 'fire_stone.png'
    },
    water_stone: {
      key: 'water_stone',
      name: 'Water Stone',
      description: 'A peculiar stone that makes certain species of Pokémon evolve. It is a clear, light blue.',
      item_type: TYPES[:evolution_stone],
      sprite: 'water_stone.png'
    },
    thunder_stone: {
      key: 'thunder_stone',
      name: 'Thunder Stone',
      description: 'A peculiar stone that makes certain species of Pokémon evolve. It has a thunderbolt pattern.',
      item_type: TYPES[:evolution_stone],
      sprite: 'thunder_stone.png'
    }
  }.freeze

  # Class method to get item definition by key
  def self.definition_for(key)
    ITEMS[key.to_sym]
  end

  # Instance method to get item definition
  def definition
    @definition ||= self.class.definition_for(key)
  end

  # Override attribute readers to pull from constants
  def name
    definition&.dig(:name) || key.titleize
  end

  def description
    definition&.dig(:description) || ""
  end

  def sprite
    definition&.dig(:sprite) || "default_item.png"
  end

  # Check if this is a pokeball
  def pokeball?
    item_type == TYPES[:pokeball]
  end

  # Check if this is an evolution stone
  def evolution_stone?
    item_type == TYPES[:evolution_stone]
  end

  def potion?
    item_type == TYPES[:potion]
  end

  def key_item?
    item_type == TYPES[:key_item]
  end
end
