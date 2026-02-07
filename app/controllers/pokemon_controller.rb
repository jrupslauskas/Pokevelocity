class PokemonController < ApplicationController
  before_action :require_login

  def celebration
    # Get celebration data from session
    celebration_data = session[:pokemon_celebration]

    unless celebration_data
      # If no celebration data in session, redirect to pokedex
      redirect_to pokedex_path and return
    end

    @pokemon = Pokemon.find_by(id: celebration_data['pokemon_id'] || celebration_data[:pokemon_id])
    @event_type = celebration_data['event_type'] || celebration_data[:event_type] # 'caught' or 'evolved'
    @ball_type = celebration_data['ball_type'] || celebration_data[:ball_type] # for catches
    @duplicate = celebration_data['duplicate'] || celebration_data[:duplicate] # for duplicate catches
    @from_pokemon_name = celebration_data['from_pokemon_name'] || celebration_data[:from_pokemon_name] # for evolutions
    @trainer = current_trainer

    unless @pokemon
      redirect_to pokedex_path and return
    end

    # Clear session data after successfully loading
    session.delete(:pokemon_celebration)
  end
end
