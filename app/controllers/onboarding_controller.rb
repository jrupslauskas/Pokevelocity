class OnboardingController < ApplicationController
  before_action :require_login
  before_action :redirect_if_completed, except: [ :choose_starter, :create_starter ]

  def welcome
    @trainer = current_trainer
  end

  def choose_starter
    @trainer = current_trainer
    @starters = Pokemon.where(pokedex_number: [ 1, 4, 7 ]).order(:pokedex_number)
  end

  def create_starter
    @trainer = current_trainer
    pokemon = Pokemon.find(params[:pokemon_id])

    # Validate it's actually a starter
    unless [ 1, 4, 7 ].include?(pokemon.pokedex_number)
      redirect_to onboarding_choose_starter_path, alert: "Please choose a valid starter Pokémon"
      return
    end

    # Give them their starter
    @trainer.captures.create!(
      pokemon: pokemon,
      ball_type: "pokeball",
      captured_at: Time.current,
      evolved: false
    )

    # Check if this is an Elite Trainer restart (already completed onboarding)
    if @trainer.onboarding_completed
      # Elite Trainer: skip sendoff, go straight to dashboard
      redirect_to dashboard_path, notice: "Welcome back, Elite Trainer! You chose #{pokemon.name}!"
    else
      # New player: continue to sendoff
      session[:starter_pokemon_id] = pokemon.id
      redirect_to onboarding_sendoff_path
    end
  end

  def sendoff
    @trainer = current_trainer

    # Get the starter Pokemon from session
    pokemon_id = session[:starter_pokemon_id]
    unless pokemon_id
      redirect_to onboarding_choose_starter_path, alert: "Please choose your starter first"
      return
    end

    @pokemon = Pokemon.find(pokemon_id)
  end

  def complete
    @trainer = current_trainer

    # Give starter items and currency
    @trainer.add_item(:pokeball, 1)
    @trainer.increment!(:currency, 100)

    # Complete onboarding
    @trainer.complete_onboarding!

    # Clear the session
    session.delete(:starter_pokemon_id)

    # Clear the cached current_trainer so it reloads with updated onboarding status
    @current_trainer = nil

    redirect_to dashboard_path, notice: "Welcome to your journey, #{@trainer.username}!"
  end

  private

  def redirect_if_completed
    redirect_to dashboard_path if current_trainer.onboarding_completed
  end
end
