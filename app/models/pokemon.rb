class Pokemon < ApplicationRecord
  has_one_attached :image

  has_many :captures, dependent: :destroy
  has_many :trainers, through: :captures

  validates :pokedex_number, presence: true, uniqueness: true,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 151 }
  validates :name, presence: true
  validates :image, presence: true
  validates :difficulty, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
end
