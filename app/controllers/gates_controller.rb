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

    # Check what items were awarded with this gate
    @awarded_items = []

    # Check for fishing rods (from GateUnlock model)
    case @gate.gate_number
    when 2
      @awarded_items << { key: :old_rod, name: "Old Rod" } if @trainer.has_item?(:old_rod)
    when 4
      @awarded_items << { key: :good_rod, name: "Good Rod" } if @trainer.has_item?(:good_rod)
    when 6
      @awarded_items << { key: :super_rod, name: "Super Rod" } if @trainer.has_item?(:super_rod)
    end

    # Check for HM Surf (from Trainer model)
    if @gate.gate_number == 5 && @trainer.has_item?(:hm_surf)
      @awarded_items << { key: :hm_surf, name: "HM03 Surf" }
    end
  end
end
