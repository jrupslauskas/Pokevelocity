class CatchesController < ApplicationController
  before_action :require_login

  def new
    @trainer = current_trainer

    # Check if there are any Pokemon in the database
    if Pokemon.count == 0
      redirect_to dashboard_path, alert: "No Pokémon available yet! Please contact an administrator."
      return
    end

    # Get all uncaught Pokemon
    caught_ids = @trainer.captured_pokemon.pluck(:id)
    @uncaught_pokemon = Pokemon.where.not(id: caught_ids).order(:pokedex_number)

    # Check if all Pokemon are caught
    if @uncaught_pokemon.empty?
      redirect_to pokedex_path, notice: "Congratulations! You've caught all 151 Pokemon!"
      return
    end

    # Get total trainer count
    @total_trainers = Trainer.count

    # Get count of trainers who have caught each Pokemon (to avoid N+1 queries)
    @pokemon_trainer_counts = Capture
      .where(pokemon_id: @uncaught_pokemon.pluck(:id))
      .group(:pokemon_id)
      .count

    # Check if trainer has any pokeballs (show message but don't redirect)
    # Only show this message if there isn't already a flash message (e.g., from a failed catch)
    if @trainer.total_pokeballs == 0 && flash[:alert].nil?
      flash.now[:alert] = "You don't have any Pokéballs! Complete tickets to earn some."
    end
  end

  def show
    @trainer = current_trainer
    @pokemon = Pokemon.find(params[:id])

    # Check if already caught
    if @trainer.captured_pokemon.include?(@pokemon)
      redirect_to catches_path, alert: "You've already caught #{@pokemon.name}!"
      return
    end

    # Get catch probabilities for each ball type
    @catch_probabilities = PokemonCatchService::CAPTURE_EFFICIENCY.transform_values do |difficulty_hash|
      difficulty_hash[@pokemon.difficulty]
    end

    # Check if trainer has any pokeballs (show message but don't redirect)
    # Only show this message if there isn't already a flash message
    if @trainer.total_pokeballs == 0 && flash[:alert].nil?
      flash.now[:alert] = "You don't have any Pokéballs! Complete tickets to earn some."
    end
  end

  def create
    @trainer = current_trainer
    @pokemon = Pokemon.find(params[:id])
    ball_type = params[:ball_type]

    result = PokemonCatchService.new(@trainer, ball_type, @pokemon).catch!

    if result[:success]
      if result[:caught]
        # Successfully caught the Pokemon
        redirect_to pokedex_path, notice: "Success! You caught #{@pokemon.name} (##{@pokemon.pokedex_number}) with a #{result[:ball_type].humanize}!"
      else
        # Pokemon broke free
        redirect_to catches_path, alert: result[:message]
      end
    else
      # Error occurred (no balls, already caught, etc.)
      redirect_to catch_path(@pokemon), alert: result[:error]
    end
  end
end
