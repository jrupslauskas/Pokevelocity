class GatesController < ApplicationController
  before_action :require_login

  def celebration
    # Get the newly unlocked gate from session
    gate_id = session.delete(:newly_unlocked_gate_id)

    unless gate_id
      # If no gate in session, redirect to catches
      redirect_to catches_path and return
    end

    @gate = Gate.find(gate_id)
    @trainer = current_trainer

    # Get rewards from the GateUnlock configuration
    rewards = GateUnlock::GATE_REWARDS[@gate.gate_number] || {}

    @awarded_items = []
    @awarded_currency = rewards[:currency] || 0

    # Build awarded items list from configuration
    if rewards[:items]
      rewards[:items].each do |item_reward|
        if @trainer.has_item?(item_reward[:key])
          @awarded_items << { key: item_reward[:key], name: item_reward[:name] }
        end
      end
    end
  end
end
