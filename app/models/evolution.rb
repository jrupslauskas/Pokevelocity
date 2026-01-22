class Evolution < ApplicationRecord
  belongs_to :from_pokemon, class_name: "Pokemon", foreign_key: "from_pokemon_id"
  belongs_to :to_pokemon, class_name: "Pokemon", foreign_key: "to_pokemon_id"

  validates :from_pokemon_id, presence: true
  validates :to_pokemon_id, presence: true
  validates :required_item_key, presence: true
  validates :required_item_quantity, presence: true, numericality: { greater_than: 0 }

  # Get the item object for this evolution
  def required_item
    @required_item ||= Item.find_by(key: required_item_key)
  end

  # Check if a trainer has enough of the required item to evolve
  def can_trainer_evolve?(trainer)
    trainer_item = trainer.trainer_items.joins(:item).find_by(items: { key: required_item_key })
    trainer_item && trainer_item.quantity >= required_item_quantity
  end
end
