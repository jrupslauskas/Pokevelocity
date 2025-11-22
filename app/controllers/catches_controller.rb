class CatchesController < ApplicationController
  before_action :require_login

  def new
    @trainer = current_trainer

    # Check if there are any routes in the database
    if Route.count == 0
      redirect_to dashboard_path, alert: "No routes available yet! Please contact an administrator."
      return
    end

    # Get all routes with their available Pokemon (excluding already caught ones)
    @routes = Route.includes(route_encounters: :pokemon).all

    # For each route, filter out Pokemon the trainer has already caught
    @route_available_pokemon = {}
    caught_ids = @trainer.captured_pokemon.pluck(:id)
    @routes.each do |route|
      available_pokemon = route.pokemon.where.not(id: caught_ids)
      @route_available_pokemon[route.id] = available_pokemon
    end

    # Check if trainer has any pokeballs (show message but don't redirect)
    # Only show this message if there isn't already a flash message
    if @trainer.total_pokeballs == 0 && flash[:alert].nil?
      flash.now[:alert] = "You don't have any Pokéballs! Complete tickets to earn some."
    end
  end

  def adventure
    @trainer = current_trainer
    route = Route.find(params[:id])

    # Get uncaught Pokemon on this route
    caught_ids = @trainer.captured_pokemon.pluck(:id)
    available_encounters = route.route_encounters.where.not(pokemon_id: caught_ids)

    if available_encounters.empty?
      redirect_to catches_path, notice: "You've caught all the Pokémon on this route!"
      return
    end

    # Calculate total weight from available encounters only
    total_weight = available_encounters.sum(:spawn_rate)
    random_value = rand(1..total_weight)

    # Find which Pokemon was encountered
    cumulative_weight = 0
    encountered_pokemon = nil
    available_encounters.includes(:pokemon).each do |encounter|
      cumulative_weight += encounter.spawn_rate
      if random_value <= cumulative_weight
        encountered_pokemon = encounter.pokemon
        break
      end
    end

    # Redirect to the encounter page for this Pokemon
    redirect_to catch_path(encountered_pokemon)
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
