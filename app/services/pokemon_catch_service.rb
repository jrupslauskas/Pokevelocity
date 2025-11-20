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
    @trainer.has_ball?(@ball_type)
  end

  def deduct_ball!
    @trainer.deduct_ball!(@ball_type)
  end

  def find_uncaught_pokemon
    # Get all Pokemon IDs the trainer has already caught
    caught_ids = @trainer.captured_pokemon.pluck(:id)

    # Find a random Pokemon that hasn't been caught yet
    Pokemon.where.not(id: caught_ids).order("RANDOM()").first
  end

  def catch_successful?(pokemon)
    # Capture efficiency matrix: each ball type has specific effectiveness against each difficulty level
    # Master Ball: 100% against all
    # Ultra Ball: Very effective against low difficulty, still good against high difficulty
    # Great Ball: Good against low difficulty, moderate against high difficulty
    # Pokeball: Likely against difficulty 1, unlikely against 4-5
    catch_rate = CAPTURE_EFFICIENCY[@ball_type][pokemon.difficulty]

    # Roll for success
    rand(1..100) <= catch_rate
  end

  # Capture efficiency matrix: Ball type vs Pokemon difficulty
  CAPTURE_EFFICIENCY = {
    "pokeball" => {
      1 => 85,  # Likely to catch easy Pokemon
      2 => 65,  # Decent chance against easy-medium
      3 => 45,  # Challenging against medium difficulty
      4 => 25,  # Pretty unlikely against hard Pokemon
      5 => 10   # Very unlikely against legendaries
    },
    "great_ball" => {
      1 => 92,  # Very high success against easy Pokemon
      2 => 75,  # Good against easy-medium
      3 => 55,  # Decent against medium difficulty
      4 => 35,  # Still challenging against hard
      5 => 18   # Better than pokeball but still tough
    },
    "ultra_ball" => {
      1 => 97,  # Very very effective against easy Pokemon
      2 => 88,  # Very high against easy-medium
      3 => 72,  # Good against medium difficulty
      4 => 52,  # Decent chance against hard Pokemon
      5 => 32   # Much better against legendaries
    },
    "master_ball" => {
      1 => 100, # Guaranteed catch
      2 => 100, # Guaranteed catch
      3 => 100, # Guaranteed catch
      4 => 100, # Guaranteed catch
      5 => 100  # Guaranteed catch
    }
  }.freeze
end
