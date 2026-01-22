class EliteTrainerController < ApplicationController
  before_action :require_login
  before_action :check_eligibility, only: [ :congratulations ]

  def congratulations
    @trainer = current_trainer
  end

  def confirm
    @trainer = current_trainer

    # Increment Elite Trainer level
    @trainer.increment!(:elite_trainer_level)

    # Reset gameplay progress
    reset_trainer_progress

    # Redirect to starter selection
    redirect_to onboarding_choose_starter_path, notice: "Welcome back, Elite Trainer! Choose your new starter Pokémon."
  end

  def decline
    redirect_to dashboard_path
  end

  private

  def check_eligibility
    # Count distinct Pokemon (not duplicate captures)
    distinct_pokemon_count = current_trainer.captures.select(:pokemon_id).distinct.count
    unless distinct_pokemon_count >= 151
      redirect_to dashboard_path, alert: "You must catch all 151 Pokémon to become an Elite Trainer."
    end
  end

  def reset_trainer_progress
    # Delete all captures (Pokémon collection)
    @trainer.captures.destroy_all

    # Delete all gate unlocks (badges)
    @trainer.gate_unlocks.destroy_all

    # Delete all items
    @trainer.trainer_items.destroy_all

    # Reset currency to 100
    @trainer.update!(currency: 100)

    # Reset adventures to 5
    @trainer.update!(adventures_remaining: 5, adventures_allocated_at: Time.current)

    # Add starting pokeball
    @trainer.add_item(:pokeball, 1)
  end
end
