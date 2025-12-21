class GateUnlock < ApplicationRecord
  belongs_to :trainer
  belongs_to :gate

  validates :trainer_id, uniqueness: { scope: :gate_id, message: "has already unlocked this gate" }
  validates :unlocked_at, presence: true

  before_validation :set_unlocked_at, on: :create
  after_create :award_gate_rewards

  private

  def set_unlocked_at
    self.unlocked_at ||= Time.current
  end

  def award_gate_rewards
    # Award fishing rods based on gate number
    item_key = case gate.gate_number
    when 3 then :old_rod
    when 5 then :good_rod
    when 7 then :super_rod
    end

    return unless item_key

    item = Item.find_by(key: item_key.to_s)
    if item
      trainer.add_item(item_key, 1)
      Rails.logger.info "Awarded #{item_key} to trainer #{trainer.username} for unlocking gate #{gate.gate_number}"
    else
      Rails.logger.error "Item #{item_key} not found when trying to award for gate #{gate.gate_number}"
    end
  end
end
