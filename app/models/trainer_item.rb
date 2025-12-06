class TrainerItem < ApplicationRecord
  belongs_to :trainer
  belongs_to :item

  validates :trainer, presence: true
  validates :item, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :trainer_id, uniqueness: { scope: :item_id, message: "already has this item" }

  # Scopes
  scope :with_quantity, -> { where("quantity > 0") }

  # Increment item quantity
  def add(amount = 1)
    increment!(:quantity, amount)
  end

  # Decrement item quantity
  def remove(amount = 1)
    return false if quantity < amount
    decrement!(:quantity, amount)
    destroy if quantity.zero?
    true
  end
end
