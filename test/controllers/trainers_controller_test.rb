require "test_helper"

class TrainersControllerTest < ActionDispatch::IntegrationTest
  # ================================================================================
  # REWARDS TESTS
  # ================================================================================

  test "should get rewards page when logged in" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_response :success
  end

  test "should redirect to login when accessing rewards without login" do
    get rewards_path
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "should successfully redeem 1 story point reward" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_total = trainer.total_pokeballs

    post rewards_path, params: { story_points: 1 }

    assert_redirected_to rewards_path
    assert_match(/Congratulations! You earned a/, flash[:notice])

    trainer.reload
    # Should have one more ball than before
    assert_equal initial_total + 1, trainer.total_pokeballs
  end

  test "should successfully redeem 2 story point reward" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_total = trainer.total_pokeballs

    post rewards_path, params: { story_points: 2 }

    assert_redirected_to rewards_path
    assert_match(/Congratulations! You earned a/, flash[:notice])

    trainer.reload
    assert_equal initial_total + 1, trainer.total_pokeballs
  end

  test "should successfully redeem 3 story point reward" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_total = trainer.total_pokeballs

    post rewards_path, params: { story_points: 3 }

    assert_redirected_to rewards_path
    assert_match(/Congratulations! You earned a/, flash[:notice])

    trainer.reload
    assert_equal initial_total + 1, trainer.total_pokeballs
  end

  test "should successfully redeem 5 story point reward" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_total = trainer.total_pokeballs

    post rewards_path, params: { story_points: 5 }

    assert_redirected_to rewards_path
    assert_match(/Congratulations! You earned a/, flash[:notice])

    trainer.reload
    assert_equal initial_total + 1, trainer.total_pokeballs
  end

  test "should successfully redeem 8 story point reward" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_total = trainer.total_pokeballs

    post rewards_path, params: { story_points: 8 }

    assert_redirected_to rewards_path
    assert_match(/Congratulations! You earned a/, flash[:notice])

    trainer.reload
    assert_equal initial_total + 1, trainer.total_pokeballs
  end

  test "should reject 0 story points" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_total = trainer.total_pokeballs

    post rewards_path, params: { story_points: 0 }

    assert_redirected_to rewards_path
    assert_equal "Please enter a valid story point value", flash[:alert]

    trainer.reload
    # No balls should be added
    assert_equal initial_total, trainer.total_pokeballs
  end

  test "should reject negative story points" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_total = trainer.total_pokeballs

    post rewards_path, params: { story_points: -5 }

    assert_redirected_to rewards_path
    assert_equal "Please enter a valid story point value", flash[:alert]

    trainer.reload
    assert_equal initial_total, trainer.total_pokeballs
  end

  test "should redirect to login when redeeming reward without login" do
    post rewards_path, params: { story_points: 5 }
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  # ================================================================================
  # POKEMON CATCHING TESTS
  # ================================================================================

  test "should get catch page when logged in" do
    log_in_as(trainers(:ash))
    get catches_path
    assert_response :success
  end

  test "should redirect to login when accessing catch page without login" do
    get catches_path
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "should show alert when trainer has no pokeballs on catch page" do
    log_in_as(trainers(:broke_trainer))
    get catches_path
    assert_response :success
    assert_equal "You don't have any Pokéballs! Complete tickets to earn some.", flash[:alert]
  end

  test "should get select pokemon page when logged in" do
    log_in_as(trainers(:ash))
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_response :success
    assert_match pokemon.name, response.body
  end

  test "should show catch probabilities for pokemon" do
    log_in_as(trainers(:ash))
    pokemon = pokemons(:pikachu)
    get catch_path(pokemon)
    assert_response :success
    # Verify the page contains probability information
    assert_match "Pikachu", response.body
  end

  test "should redirect when trying to select already caught pokemon" do
    log_in_as(trainers(:gary))
    pokemon = pokemons(:charmander) # Gary already caught this

    get catch_path(pokemon)
    assert_redirected_to catches_path
    assert_equal "You've already caught #{pokemon.name}!", flash[:alert]
  end

  test "should redirect to login when accessing select pokemon without login" do
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "should show alert when trainer has no pokeballs on select pokemon page" do
    log_in_as(trainers(:broke_trainer))
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_response :success
    assert_equal "You don't have any Pokéballs! Complete tickets to earn some.", flash[:alert]
  end

  test "should successfully catch pokemon with master ball" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)

    initial_master_balls = trainer.master_balls_count

    # Master ball has 100% catch rate
    post catch_path(pokemon), params: { ball_type: "master_ball" }

    assert_redirected_to pokedex_path
    assert_match(/Success! You caught #{pokemon.name}/, flash[:notice])

    trainer.reload
    assert_includes trainer.captured_pokemon, pokemon
    assert_equal initial_master_balls - 1, trainer.master_balls_count
  end

  test "should use pokeball when attempting catch" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)

    initial_pokeballs = trainer.pokeballs_count

    post catch_path(pokemon), params: { ball_type: "pokeball" }

    trainer.reload
    # Ball should be used regardless of success
    assert_equal initial_pokeballs - 1, trainer.pokeballs_count
  end

  test "should use great ball when attempting catch" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)

    initial_great_balls = trainer.great_balls_count

    post catch_path(pokemon), params: { ball_type: "great_ball" }

    trainer.reload
    assert_equal initial_great_balls - 1, trainer.great_balls_count
  end

  test "should use ultra ball when attempting catch" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)

    initial_ultra_balls = trainer.ultra_balls_count

    post catch_path(pokemon), params: { ball_type: "ultra_ball" }

    trainer.reload
    assert_equal initial_ultra_balls - 1, trainer.ultra_balls_count
  end

  test "should not catch pokemon when trainer has no balls" do
    trainer = trainers(:broke_trainer)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)

    post catch_path(pokemon), params: { ball_type: "pokeball" }

    assert_redirected_to catch_path(pokemon)
    assert_match(/You don't have any/, flash[:alert])

    trainer.reload
    assert_not_includes trainer.captured_pokemon, pokemon
  end

  test "should not catch already caught pokemon" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    pokemon = pokemons(:charmander) # Gary already caught this

    initial_pokeballs = trainer.pokeballs_count

    post catch_path(pokemon), params: { ball_type: "pokeball" }

    assert_redirected_to catch_path(pokemon)
    assert_match(/already caught/, flash[:alert])

    trainer.reload
    # Ball should not be used
    assert_equal initial_pokeballs, trainer.pokeballs_count
  end

  test "should redirect to login when attempting catch without login" do
    pokemon = pokemons(:bulbasaur)
    post catch_path(pokemon), params: { ball_type: "pokeball" }
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "catch attempt should create capture record on success" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)

    assert_difference("Capture.count", 1) do
      post catch_path(pokemon), params: { ball_type: "master_ball" }
    end

    # Check that capture record was created with correct attributes
    trainer.reload
    assert_includes trainer.captured_pokemon, pokemon
    capture = Capture.find_by(trainer: trainer, pokemon: pokemon)
    assert_not_nil capture
    assert_equal "master_ball", capture.ball_type
    assert_not_nil capture.captured_at
  end

  test "should redirect to pokedex when all pokemon are caught" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Catch all pokemon
    Pokemon.all.each do |pokemon|
      Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball") unless trainer.captured_pokemon.include?(pokemon)
    end

    get catches_path
    assert_redirected_to pokedex_path
    assert_match "Congratulations!", flash[:notice]
  end

  test "should redirect to dashboard when no pokemon exist in database" do
    log_in_as(trainers(:ash))

    # Delete all pokemon
    Pokemon.destroy_all

    get catches_path
    assert_redirected_to dashboard_path
    assert_equal "No Pokémon available yet! Please contact an administrator.", flash[:alert]
  end

  test "should filter out caught pokemon from uncaught list" do
    trainer = trainers(:gary)
    log_in_as(trainer)

    get catches_path

    # Verify the page shows uncaught pokemon but not caught ones
    assert_response :success
    assert_match "Bulbasaur", response.body
  end

  private

  # Helper method to log in a trainer
  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end
end
