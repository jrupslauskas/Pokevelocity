class Item < ApplicationRecord
  has_many :trainer_items, dependent: :destroy
  has_many :trainers, through: :trainer_items

  validates :key, presence: true, uniqueness: true
  validates :item_type, presence: true, inclusion: { in: %w[pokeball evolution_stone potion key_item] }

  # Item types
  TYPES = {
    pokeball: "pokeball",
    evolution_stone: "evolution_stone",
    potion: "potion",
    key_item: "key_item"
  }.freeze

  # All items defined as constants
  ITEMS = {
    pokeball: {
      key: "pokeball",
      name: "Poké Ball",
      description: "A device for catching wild Pokémon. It is designed as a capsule system.",
      item_type: TYPES[:pokeball],
      sprite: "pokeball_shop.png",
      buy_price: 200,
      sell_price: 100
    },
    great_ball: {
      key: "great_ball",
      name: "Great Ball",
      description: "A good, high-performance Poké Ball that provides a higher Pokémon catch rate than a standard Poké Ball.",
      item_type: TYPES[:pokeball],
      sprite: "greatball.png",
      buy_price: 300,
      sell_price: 200
    },
    ultra_ball: {
      key: "ultra_ball",
      name: "Ultra Ball",
      description: "An ultra-high performance Poké Ball that provides a higher success rate for catching Pokémon than a Great Ball.",
      item_type: TYPES[:pokeball],
      sprite: "ultraball.jpg",
      buy_price: 400,
      sell_price: 300
    },
    master_ball: {
      key: "master_ball",
      name: "Master Ball",
      description: "The best Poké Ball with the ultimate level of performance. It will catch any wild Pokémon without fail.",
      item_type: TYPES[:pokeball],
      sprite: "masterball.png",
      buy_price: 700,
      sell_price: 500
    },
    fire_stone: {
      key: "fire_stone",
      name: "Fire Stone",
      description: "A peculiar stone that makes certain species of Pokémon evolve. It burns as red as the evening sun.",
      item_type: TYPES[:evolution_stone],
      sprite: "firestone.png",
      buy_price: 300,
      sell_price: 200
    },
    water_stone: {
      key: "water_stone",
      name: "Water Stone",
      description: "A peculiar stone that makes certain species of Pokémon evolve. It is a clear, light blue.",
      item_type: TYPES[:evolution_stone],
      sprite: "waterstone.png",
      buy_price: 300,
      sell_price: 200
    },
    thunder_stone: {
      key: "thunder_stone",
      name: "Thunder Stone",
      description: "A peculiar stone that makes certain species of Pokémon evolve. It has a thunderbolt pattern.",
      item_type: TYPES[:evolution_stone],
      sprite: "thunderstone.png",
      buy_price: 300,
      sell_price: 200
    },
    moon_stone: {
      key: "moon_stone",
      name: "Moon Stone",
      description: "A peculiar stone that makes certain species of Pokémon evolve. It is as black as the night sky.",
      item_type: TYPES[:evolution_stone],
      sprite: "moonstone.png",
      buy_price: 300,
      sell_price: 200
    },
    leaf_stone: {
      key: "leaf_stone",
      name: "Leaf Stone",
      description: "A peculiar stone that makes certain species of Pokémon evolve. It has a leaf pattern.",
      item_type: TYPES[:evolution_stone],
      sprite: "leafstone.png",
      buy_price: 300,
      sell_price: 200
    },
    transfer_cable: {
      key: "transfer_cable",
      name: "Transfer Cable",
      description: "A special cable that allows certain Pokémon to evolve by simulating a trade connection.",
      item_type: TYPES[:evolution_stone],
      sprite: "transfer_cable.png",
      buy_price: 300,
      sell_price: 200
    },
    evolution_stone: {
      key: "evolution_stone",
      name: "Evolution Stone",
      description: "A mysterious stone used to evolve most Pokémon",
      item_type: TYPES[:evolution_stone],
      sprite: "evolution_stone.png",
      buy_price: 100,
      sell_price: 100
    },
    old_rod: {
      key: "old_rod",
      name: "Old Rod",
      description: "An old fishing rod that can be used to catch Pokémon in water. Awarded for defeating Misty at Cerulean Gym.",
      item_type: TYPES[:key_item],
      sprite: "old_rod.png",
      buy_price: nil,
      sell_price: nil
    },
    good_rod: {
      key: "good_rod",
      name: "Good Rod",
      description: "A decent fishing rod that can catch a greater variety of Pokémon than the Old Rod. Awarded for defeating Erika at Celadon Gym.",
      item_type: TYPES[:key_item],
      sprite: "good_rod.png",
      buy_price: nil,
      sell_price: nil
    },
    super_rod: {
      key: "super_rod",
      name: "Super Rod",
      description: "The best fishing rod available. It can catch the rarest water-dwelling Pokémon. Awarded for defeating Sabrina at Saffron Gym.",
      item_type: TYPES[:key_item],
      sprite: "super_rod.png",
      buy_price: nil,
      sell_price: nil
    },
    hm_surf: {
      key: "hm_surf",
      name: "HM03 Surf",
      description: "A Hidden Machine that teaches the move Surf, allowing travel across water. Awarded for defeating Koga at Fuchsia Gym.",
      item_type: TYPES[:key_item],
      sprite: "hm_surf.png",
      buy_price: nil,
      sell_price: nil
    },
    potion: {
      key: "potion",
      name: "Potion",
      description: "A spray-type medicine for treating wounds. It restores up to 3 adventures.",
      item_type: TYPES[:potion],
      sprite: "potion.png",
      buy_price: 100,
      sell_price: 100,
      adventure_restore: 3
    },
    super_potion: {
      key: "super_potion",
      name: "Super Potion",
      description: "A strong spray-type medicine for treating wounds. It restores up to 6 adventures.",
      item_type: TYPES[:potion],
      sprite: "super_potion.png",
      buy_price: 200,
      sell_price: 200,
      adventure_restore: 6
    },
    hyper_potion: {
      key: "hyper_potion",
      name: "Hyper Potion",
      description: "A powerful spray-type medicine for treating wounds. It restores up to 10 adventures.",
      item_type: TYPES[:potion],
      sprite: "hyper_potion.png",
      buy_price: 300,
      sell_price: 300,
      adventure_restore: 10
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

  def buy_price
    definition&.dig(:buy_price)
  end

  def sell_price
    definition&.dig(:sell_price)
  end

  def adventure_restore
    definition&.dig(:adventure_restore)
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
