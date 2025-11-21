class TrainerPlazaController < ApplicationController
  before_action :require_login

  def index
    @trainers = Trainer.all.order(:username)
  end

  def show
    @trainer = Trainer.find(params[:id])
    @captured_pokemon = @trainer.captured_pokemon.order(:pokedex_number)
  end
end
