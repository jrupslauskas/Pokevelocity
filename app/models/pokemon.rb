class Pokemon < ApplicationRecord
  has_one_attached :image

  has_many :captures, dependent: :destroy
  has_many :trainers, through: :captures

  validates :pokedex_number, presence: true, uniqueness: true,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 151 }
  validates :name, presence: true
  validates :image, presence: true
end
