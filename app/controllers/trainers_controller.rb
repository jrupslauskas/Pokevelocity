class TrainersController < ApplicationController
  before_action :require_login, only: [:dashboard, :pokedex]

  def new
    @trainer = Trainer.new
    @pokemon = Pokemon.order(:pokedex_number)
  end

  def create
    @trainer = Trainer.new(trainer_params)
    @pokemon = Pokemon.order(:pokedex_number)

    # Validate activation code
    activation_code = params[:activation_code]
    valid_code = ValidationCode.find_by(active: true)

    if valid_code.nil? || activation_code.upcase != valid_code.code
      @trainer.errors.add(:base, "Invalid activation code")
      render :new, status: :unprocessable_entity
      return
    end

    if @trainer.save
      session[:trainer_id] = @trainer.id
      redirect_to dashboard_path, notice: "Welcome to Pokevelocity, #{@trainer.username}!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def dashboard
    @trainer = current_trainer
  end

  def pokedex
    @trainer = current_trainer
    @captured_pokemon = @trainer.captured_pokemon.order(:pokedex_number)
  end

  private

  def trainer_params
    params.require(:trainer).permit(:username, :password, :icon_pokemon_id)
  end
end
