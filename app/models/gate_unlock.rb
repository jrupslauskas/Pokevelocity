class GateUnlock < ApplicationRecord
  belongs_to :trainer
  belongs_to :gate

  validates :trainer_id, uniqueness: { scope: :gate_id, message: "has already unlocked this gate" }
  validates :unlocked_at, presence: true

  before_validation :set_unlocked_at, on: :create

  private

  def set_unlocked_at
    self.unlocked_at ||= Time.current
  end
end
