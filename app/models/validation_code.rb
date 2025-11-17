class ValidationCode < ApplicationRecord
  validates :code, presence: true, length: { is: 6 }
  validates :code, uniqueness: true
end
