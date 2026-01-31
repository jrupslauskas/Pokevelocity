class TrainerPlazaController < ApplicationController
  before_action :require_login

  def index
    @trainers = Trainer.all.order(:username)
  end

  def show
    @trainer = Trainer.includes(gate_unlocks: :gate).find(params[:id])
    @captured_pokemon = @trainer.captured_pokemon.order(:pokedex_number)
    @total_trainers = Trainer.count

    # Calculate how many trainers have caught each Pokémon
    # Build a hash: { pokemon_id => count_of_trainers }
    @pokemon_trainer_counts = Capture.where(pokemon_id: @captured_pokemon.pluck(:id))
                                     .select(:pokemon_id)
                                     .group(:pokemon_id)
                                     .distinct
                                     .count("DISTINCT trainer_id")
  end
end
