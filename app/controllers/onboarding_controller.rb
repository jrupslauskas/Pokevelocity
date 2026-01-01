class OnboardingController < ApplicationController
  before_action :require_login
  before_action :redirect_if_completed

  def welcome
    @trainer = current_trainer
  end

  def choose_starter
    @trainer = current_trainer
    @starters = Pokemon.where(pokedex_number: [1, 4, 7]).order(:pokedex_number)
  end

  def create_starter
    @trainer = current_trainer
    pokemon = Pokemon.find(params[:pokemon_id])

    # Validate it's actually a starter
    unless [1, 4, 7].include?(pokemon.pokedex_number)
      redirect_to onboarding_choose_starter_path, alert: "Please choose a valid starter Pokémon"
      return
    end

    # Give them their starter
    @trainer.captures.create!(
      pokemon: pokemon,
      ball_type: 'pokeball',
      captured_at: Time.current,
      evolved: false
    )

    # Give starter items
    @trainer.add_item(:pokeball, 1)

    # Complete onboarding
    @trainer.complete_onboarding!

    # Clear the cached current_trainer so it reloads with updated onboarding status
    @current_trainer = nil

    redirect_to dashboard_path, notice: "Welcome to your journey with #{pokemon.name.capitalize}!"
  end

  private

  def redirect_if_completed
    redirect_to dashboard_path if current_trainer.onboarding_completed
  end
end
