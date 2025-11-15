class PokemonCatchService
  def initialize(trainer, ball_type, pokemon = nil)
    @trainer = trainer
    @ball_type = ball_type
    @pokemon = pokemon
  end

  def catch!
    # Validate ball type
    unless Capture::BALL_TYPES.include?(@ball_type)
      return { success: false, error: "Invalid ball type" }
    end

    # Check if trainer has the ball
    unless has_ball?
      return { success: false, error: "You don't have any #{@ball_type.humanize}s!" }
    end

    # Get the Pokemon to catch (either specified or random)
    pokemon_to_catch = @pokemon || find_uncaught_pokemon
    unless pokemon_to_catch
      return { success: false, error: "You've already caught all 151 Pokemon! Congratulations!" }
    end

    # Check if already caught
    if @trainer.captured_pokemon.include?(pokemon_to_catch)
      return { success: false, error: "You've already caught #{pokemon_to_catch.name}!" }
    end

    # Deduct the ball (ball is used regardless of success)
    deduct_ball!

    # Check if catch is successful based on difficulty and ball type
    if catch_successful?(pokemon_to_catch)
      # Create the capture
      capture = @trainer.captures.create!(
        pokemon: pokemon_to_catch,
        ball_type: @ball_type
      )

      {
        success: true,
        caught: true,
        pokemon: pokemon_to_catch,
        capture: capture,
        ball_type: @ball_type
      }
    else
      # Catch failed, but ball was still used
      {
        success: true,
        caught: false,
        pokemon: pokemon_to_catch,
        ball_type: @ball_type,
        message: "#{pokemon_to_catch.name} broke free! The #{@ball_type.humanize} was lost."
      }
    end
  rescue StandardError => e
    {
      success: false,
      error: "Something went wrong: #{e.message}"
    }
  end

  private

  def has_ball?
    case @ball_type
    when "pokeball"
      @trainer.pokeballs_count > 0
    when "great_ball"
      @trainer.great_balls_count > 0
    when "ultra_ball"
      @trainer.ultra_balls_count > 0
    when "master_ball"
      @trainer.master_balls_count > 0
    else
      false
    end
  end

  def deduct_ball!
    case @ball_type
    when "pokeball"
      @trainer.pokeballs_count -= 1
    when "great_ball"
      @trainer.great_balls_count -= 1
    when "ultra_ball"
      @trainer.ultra_balls_count -= 1
    when "master_ball"
      @trainer.master_balls_count -= 1
    end

    @trainer.save!
  end

  def find_uncaught_pokemon
    # Get all Pokemon IDs the trainer has already caught
    caught_ids = @trainer.captured_pokemon.pluck(:id)

    # Find a random Pokemon that hasn't been caught yet
    Pokemon.where.not(id: caught_ids).order("RANDOM()").first
  end

  def catch_successful?(pokemon)
    # Master Ball always succeeds
    return true if @ball_type == "master_ball"

    # Base catch rate by difficulty
    base_rate = case pokemon.difficulty
                when 1 then 90  # Very easy
                when 2 then 70  # Easy
                when 3 then 50  # Medium
                when 4 then 30  # Hard
                when 5 then 10  # Very hard (legendaries)
                else 50
                end

    # Ball type bonus
    ball_bonus = case @ball_type
                 when "pokeball" then 0
                 when "great_ball" then 15
                 when "ultra_ball" then 25
                 else 0
                 end

    # Calculate final catch rate (capped at 95% max, except Master Ball)
    catch_rate = [base_rate + ball_bonus, 95].min

    # Roll for success
    rand(1..100) <= catch_rate
  end
end
