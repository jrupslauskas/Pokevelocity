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
    assert_equal "fire_stone.png", item.sprite
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
end
