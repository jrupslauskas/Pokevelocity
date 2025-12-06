require "test_helper"

class TrainerItemTest < ActiveSupport::TestCase
  def setup
    @trainer = Trainer.create!(
      username: "test_trainer_for_items",
      password: "password123"
    )
    @item = Item.create!(
      key: "test_stone",
      item_type: Item::TYPES[:evolution_stone]
    )
  end

  test "should create trainer_item with valid attributes" do
    trainer_item = TrainerItem.new(
      trainer: @trainer,
      item: @item,
      quantity: 3
    )
    assert trainer_item.valid?
  end

  test "should require trainer" do
    trainer_item = TrainerItem.new(item: @item, quantity: 1)
    assert_not trainer_item.valid?
    assert_includes trainer_item.errors[:trainer], "can't be blank"
  end

  test "should require item" do
    trainer_item = TrainerItem.new(trainer: @trainer, quantity: 1)
    assert_not trainer_item.valid?
    assert_includes trainer_item.errors[:item], "can't be blank"
  end

  test "should default quantity to 0" do
    trainer_item = TrainerItem.new(trainer: @trainer, item: @item)
    # Quantity defaults to 0 from database schema
    assert_equal 0, trainer_item.quantity
  end

  test "should validate quantity is an integer" do
    trainer_item = TrainerItem.new(trainer: @trainer, item: @item, quantity: 1.5)
    assert_not trainer_item.valid?
    assert_includes trainer_item.errors[:quantity], "must be an integer"
  end

  test "should validate quantity is not negative" do
    trainer_item = TrainerItem.new(trainer: @trainer, item: @item, quantity: -1)
    assert_not trainer_item.valid?
    assert_includes trainer_item.errors[:quantity], "must be greater than or equal to 0"
  end

  test "should validate unique trainer and item combination" do
    TrainerItem.create!(trainer: @trainer, item: @item, quantity: 1)
    duplicate = TrainerItem.new(trainer: @trainer, item: @item, quantity: 2)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:trainer_id], "already has this item"
  end

  test "add should increment quantity" do
    trainer_item = TrainerItem.create!(trainer: @trainer, item: @item, quantity: 5)
    trainer_item.add(3)
    assert_equal 8, trainer_item.quantity
  end

  test "add should default to incrementing by 1" do
    trainer_item = TrainerItem.create!(trainer: @trainer, item: @item, quantity: 5)
    trainer_item.add
    assert_equal 6, trainer_item.quantity
  end

  test "remove should decrement quantity" do
    trainer_item = TrainerItem.create!(trainer: @trainer, item: @item, quantity: 5)
    result = trainer_item.remove(2)
    assert result
    assert_equal 3, trainer_item.quantity
  end

  test "remove should default to decrementing by 1" do
    trainer_item = TrainerItem.create!(trainer: @trainer, item: @item, quantity: 5)
    result = trainer_item.remove
    assert result
    assert_equal 4, trainer_item.quantity
  end

  test "remove should return false if quantity insufficient" do
    trainer_item = TrainerItem.create!(trainer: @trainer, item: @item, quantity: 2)
    result = trainer_item.remove(5)
    assert_not result
    assert_equal 2, trainer_item.quantity
  end

  test "remove should destroy record when quantity reaches zero" do
    trainer_item = TrainerItem.create!(trainer: @trainer, item: @item, quantity: 3)
    trainer_item.remove(3)
    assert_not TrainerItem.exists?(trainer_item.id)
  end

  test "with_quantity scope should only return items with positive quantity" do
    TrainerItem.create!(trainer: @trainer, item: @item, quantity: 0)
    other_item = items(:fire_stone) # Use fixture item instead of creating
    positive_item = TrainerItem.create!(trainer: @trainer, item: other_item, quantity: 5)

    # Check that the scope includes positive quantity items and excludes zero quantity items
    items_with_quantity = TrainerItem.with_quantity.where(trainer: @trainer)
    assert_includes items_with_quantity, positive_item
    assert_equal 1, items_with_quantity.count # Only the one we just created for @trainer
  end

  test "should belong to trainer" do
    association = TrainerItem.reflect_on_association(:trainer)
    assert_equal :belongs_to, association.macro
  end

  test "should belong to item" do
    association = TrainerItem.reflect_on_association(:item)
    assert_equal :belongs_to, association.macro
  end
end
