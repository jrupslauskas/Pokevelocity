require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "should have valid ITEMS constant" do
    assert Item::ITEMS.is_a?(Hash)
    assert_not_empty Item::ITEMS
  end

  test "should create item with valid attributes" do
    item = Item.new(
      key: "test_stone",
      item_type: Item::TYPES[:evolution_stone]
    )
    assert item.valid?
  end

  test "should require key" do
    item = Item.new(item_type: Item::TYPES[:evolution_stone])
    assert_not item.valid?
    assert_includes item.errors[:key], "can't be blank"
  end

  test "should require unique key" do
    Item.create!(key: "unique_stone", item_type: Item::TYPES[:evolution_stone])
    duplicate = Item.new(key: "unique_stone", item_type: Item::TYPES[:evolution_stone])
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  end

  test "should require item_type" do
    item = Item.new(key: "test_stone")
    assert_not item.valid?
    assert_includes item.errors[:item_type], "can't be blank"
  end

  test "should validate item_type inclusion" do
    item = Item.new(key: "test_stone", item_type: "invalid_type")
    assert_not item.valid?
    assert_includes item.errors[:item_type], "is not included in the list"
  end

  test "should return name from definition" do
    item = Item.new(key: "fire_stone", item_type: Item::TYPES[:evolution_stone])
    assert_equal "Fire Stone", item.name
  end

  test "should return description from definition" do
    item = Item.new(key: "fire_stone", item_type: Item::TYPES[:evolution_stone])
    assert_includes item.description, "peculiar stone"
  end

  test "should return sprite from definition" do
    item = Item.new(key: "fire_stone", item_type: Item::TYPES[:evolution_stone])
    assert_equal "firestone.png", item.sprite
  end

  test "should fallback to titleized key for undefined item name" do
    item = Item.new(key: "unknown_item", item_type: Item::TYPES[:key_item])
    assert_equal "Unknown Item", item.name
  end

  test "evolution_stone? should return true for evolution stones" do
    item = Item.new(key: "fire_stone", item_type: Item::TYPES[:evolution_stone])
    assert item.evolution_stone?
    assert_not item.potion?
    assert_not item.key_item?
  end

  test "potion? should return true for potions" do
    item = Item.new(key: "potion", item_type: Item::TYPES[:potion])
    assert item.potion?
    assert_not item.evolution_stone?
    assert_not item.key_item?
  end

  test "key_item? should return true for key items" do
    item = Item.new(key: "bicycle", item_type: Item::TYPES[:key_item])
    assert item.key_item?
    assert_not item.evolution_stone?
    assert_not item.potion?
  end

  test "should have trainer_items association" do
    item = Item.reflect_on_association(:trainer_items)
    assert_equal :has_many, item.macro
  end

  test "should have trainers association through trainer_items" do
    item = Item.reflect_on_association(:trainers)
    assert_equal :has_many, item.macro
    assert_equal :trainer_items, item.options[:through]
  end

  # ================================================================================
  # FISHING ROD TESTS
  # ================================================================================

  test "old_rod should be a key_item" do
    old_rod = items(:old_rod)
    assert_equal "key_item", old_rod.item_type
    assert old_rod.key_item?
  end

  test "good_rod should be a key_item" do
    good_rod = items(:good_rod)
    assert_equal "key_item", good_rod.item_type
    assert good_rod.key_item?
  end

  test "super_rod should be a key_item" do
    super_rod = items(:super_rod)
    assert_equal "key_item", super_rod.item_type
    assert super_rod.key_item?
  end

  test "old_rod should not have buy_price" do
    definition = Item::ITEMS[:old_rod]
    assert_nil definition[:buy_price], "Old Rod should not be buyable"
  end

  test "old_rod should not have sell_price" do
    definition = Item::ITEMS[:old_rod]
    assert_nil definition[:sell_price], "Old Rod should not be sellable"
  end

  test "good_rod should not have buy_price" do
    definition = Item::ITEMS[:good_rod]
    assert_nil definition[:buy_price], "Good Rod should not be buyable"
  end

  test "good_rod should not have sell_price" do
    definition = Item::ITEMS[:good_rod]
    assert_nil definition[:sell_price], "Good Rod should not be sellable"
  end

  test "super_rod should not have buy_price" do
    definition = Item::ITEMS[:super_rod]
    assert_nil definition[:buy_price], "Super Rod should not be buyable"
  end

  test "super_rod should not have sell_price" do
    definition = Item::ITEMS[:super_rod]
    assert_nil definition[:sell_price], "Super Rod should not be sellable"
  end

  test "old_rod should have correct name" do
    old_rod = items(:old_rod)
    assert_equal "Old Rod", old_rod.name
  end

  test "good_rod should have correct name" do
    good_rod = items(:good_rod)
    assert_equal "Good Rod", good_rod.name
  end

  test "super_rod should have correct name" do
    super_rod = items(:super_rod)
    assert_equal "Super Rod", super_rod.name
  end

  test "old_rod description should mention Misty" do
    old_rod = items(:old_rod)
    assert_includes old_rod.description, "Misty"
    assert_includes old_rod.description, "Cerulean Gym"
  end

  test "good_rod description should mention Erika" do
    good_rod = items(:good_rod)
    assert_includes good_rod.description, "Erika"
    assert_includes good_rod.description, "Celadon Gym"
  end

  test "super_rod description should mention Sabrina" do
    super_rod = items(:super_rod)
    assert_includes super_rod.description, "Sabrina"
    assert_includes super_rod.description, "Saffron Gym"
  end

  test "all fishing rods should exist in ITEMS constant" do
    assert Item::ITEMS.key?(:old_rod), "Old Rod should be defined"
    assert Item::ITEMS.key?(:good_rod), "Good Rod should be defined"
    assert Item::ITEMS.key?(:super_rod), "Super Rod should be defined"
  end

  test "fishing rods should have correct keys" do
    assert_equal "old_rod", Item::ITEMS[:old_rod][:key]
    assert_equal "good_rod", Item::ITEMS[:good_rod][:key]
    assert_equal "super_rod", Item::ITEMS[:super_rod][:key]
  end

  # ================================================================================
  # POTION TESTS
  # ================================================================================

  test "all potions should exist in ITEMS constant" do
    assert Item::ITEMS.key?(:potion), "Potion should be defined"
    assert Item::ITEMS.key?(:super_potion), "Super Potion should be defined"
    assert Item::ITEMS.key?(:hyper_potion), "Hyper Potion should be defined"
  end

  test "potions should have correct keys" do
    assert_equal "potion", Item::ITEMS[:potion][:key]
    assert_equal "super_potion", Item::ITEMS[:super_potion][:key]
    assert_equal "hyper_potion", Item::ITEMS[:hyper_potion][:key]
  end

  test "potions should be potion type" do
    potion_def = Item::ITEMS[:potion]
    super_potion_def = Item::ITEMS[:super_potion]
    hyper_potion_def = Item::ITEMS[:hyper_potion]

    assert_equal Item::TYPES[:potion], potion_def[:item_type]
    assert_equal Item::TYPES[:potion], super_potion_def[:item_type]
    assert_equal Item::TYPES[:potion], hyper_potion_def[:item_type]
  end

  test "potion should have correct prices and adventure restore" do
    definition = Item::ITEMS[:potion]
    assert_equal 100, definition[:buy_price]
    assert_equal 100, definition[:sell_price]
    assert_equal 3, definition[:adventure_restore]
  end

  test "super_potion should have correct prices and adventure restore" do
    definition = Item::ITEMS[:super_potion]
    assert_equal 200, definition[:buy_price]
    assert_equal 200, definition[:sell_price]
    assert_equal 6, definition[:adventure_restore]
  end

  test "hyper_potion should have correct prices and adventure restore" do
    definition = Item::ITEMS[:hyper_potion]
    assert_equal 300, definition[:buy_price]
    assert_equal 300, definition[:sell_price]
    assert_equal 10, definition[:adventure_restore]
  end

  # ================================================================================
  # POKEBALL PRICE TESTS
  # ================================================================================

  test "pokeball should have correct prices" do
    definition = Item::ITEMS[:pokeball]
    assert_equal 150, definition[:buy_price]
    assert_equal 100, definition[:sell_price]
  end

  test "great_ball should have correct prices" do
    definition = Item::ITEMS[:great_ball]
    assert_equal 250, definition[:buy_price]
    assert_equal 200, definition[:sell_price]
  end

  test "ultra_ball should have correct prices" do
    definition = Item::ITEMS[:ultra_ball]
    assert_equal 350, definition[:buy_price]
    assert_equal 300, definition[:sell_price]
  end

  test "master_ball should have correct prices" do
    definition = Item::ITEMS[:master_ball]
    assert_equal 500, definition[:buy_price]
    assert_equal 400, definition[:sell_price]
  end

  # ================================================================================
  # EVOLUTION STONE PRICE TESTS
  # ================================================================================

  test "fire_stone should have correct prices" do
    definition = Item::ITEMS[:fire_stone]
    assert_equal 250, definition[:buy_price]
    assert_equal 200, definition[:sell_price]
  end

  test "water_stone should have correct prices" do
    definition = Item::ITEMS[:water_stone]
    assert_equal 250, definition[:buy_price]
    assert_equal 200, definition[:sell_price]
  end

  test "evolution_stone should have correct prices" do
    definition = Item::ITEMS[:evolution_stone]
    assert_equal 100, definition[:buy_price]
    assert_equal 100, definition[:sell_price]
  end

  test "potion should have correct name" do
    item = Item.new(key: "potion", item_type: Item::TYPES[:potion])
    assert_equal "Potion", item.name
  end

  test "super_potion should have correct name" do
    item = Item.new(key: "super_potion", item_type: Item::TYPES[:potion])
    assert_equal "Super Potion", item.name
  end

  test "hyper_potion should have correct name" do
    item = Item.new(key: "hyper_potion", item_type: Item::TYPES[:potion])
    assert_equal "Hyper Potion", item.name
  end

  test "potion descriptions should mention adventure restoration" do
    potion = Item.new(key: "potion", item_type: Item::TYPES[:potion])
    super_potion = Item.new(key: "super_potion", item_type: Item::TYPES[:potion])
    hyper_potion = Item.new(key: "hyper_potion", item_type: Item::TYPES[:potion])

    assert_includes potion.description, "3 adventures"
    assert_includes super_potion.description, "6 adventures"
    assert_includes hyper_potion.description, "10 adventures"
  end

  test "adventure_restore should return correct values" do
    potion = Item.new(key: "potion", item_type: Item::TYPES[:potion])
    super_potion = Item.new(key: "super_potion", item_type: Item::TYPES[:potion])
    hyper_potion = Item.new(key: "hyper_potion", item_type: Item::TYPES[:potion])

    assert_equal 3, potion.adventure_restore
    assert_equal 6, super_potion.adventure_restore
    assert_equal 10, hyper_potion.adventure_restore
  end

  test "adventure_restore should return nil for non-potion items" do
    item = Item.new(key: "fire_stone", item_type: Item::TYPES[:evolution_stone])
    assert_nil item.adventure_restore
  end
end
