class TrainersController < ApplicationController
  before_action :require_login, only: [:dashboard, :pokedex, :leaderboard, :rewards, :redeem_reward, :catch, :select_pokemon, :attempt_catch]

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

  def leaderboard
    # Get all trainers with their captured Pokémon and calculate difficulty scores
    trainers = Trainer.includes(:captured_pokemon, :icon_pokemon).all.map do |trainer|
      difficulty_score = trainer.captured_pokemon.sum(:difficulty)
      {
        trainer: trainer,
        pokemon_count: trainer.captured_pokemon.count,
        difficulty_score: difficulty_score
      }
    end

    # Sort by difficulty score (descending), then by pokemon count (descending)
    trainers = trainers.sort_by { |t| [-t[:difficulty_score], -t[:pokemon_count]] }

    # Create 14 static slots for legendary trainers
    slot_names = [
      "Red",
      "Blue",
      "Lance",
      "Agatha",
      "Bruno",
      "Lorelei",
      "Giovanni",
      "Blaine",
      "Sabrina",
      "Koga",
      "Erika",
      "Lt. Surge",
      "Misty",
      "Brock"
    ]

    @leaderboard_slots = (1..14).map do |position|
      trainer_data = trainers[position - 1] # Get trainer at this position (0-indexed)

      {
        position: position,
        title: slot_names[position - 1],
        trainer_data: trainer_data # Will be nil if no trainer holds this position
      }
    end
  end

  def rewards
    @trainer = current_trainer
  end

  def redeem_reward
    @trainer = current_trainer
    story_points = params[:story_points].to_i

    if story_points > 0
      result = @trainer.award_pokeball_for_ticket(story_points)
      redirect_to rewards_path, notice: "Congratulations! You earned a #{result[:ball_type].humanize} for completing a #{story_points} point ticket!"
    else
      redirect_to rewards_path, alert: "Please enter a valid story point value"
    end
  end

  def catch
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

    # Check if trainer has any pokeballs (show message but don't redirect)
    # Only show this message if there isn't already a flash message (e.g., from a failed catch)
    if @trainer.total_pokeballs == 0 && flash[:alert].nil?
      flash.now[:alert] = "You don't have any Pokéballs! Complete tickets to earn some."
    end
  end

  def select_pokemon
    @trainer = current_trainer
    @pokemon = Pokemon.find(params[:id])

    # Check if already caught
    if @trainer.captured_pokemon.include?(@pokemon)
      redirect_to catch_pokemon_path, alert: "You've already caught #{@pokemon.name}!"
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

  def attempt_catch
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
        redirect_to catch_pokemon_path, alert: result[:message]
      end
    else
      # Error occurred (no balls, already caught, etc.)
      redirect_to select_pokemon_path(@pokemon), alert: result[:error]
    end
  end

  private

  def trainer_params
    params.require(:trainer).permit(:username, :password, :icon_pokemon_id)
  end
end
