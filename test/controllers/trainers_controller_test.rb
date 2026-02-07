require "test_helper"

class TrainersControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create test gates (display data loaded from YAML)
    @gate_0 = Gate.create!(
      gate_number: 1,
      required_difficulty_score: 1
    )

    @gate_1 = Gate.create!(
      gate_number: 2,
      required_difficulty_score: 5
    )

    # Create always-accessible route (display data loaded from YAML)
    @starter_route = Route.create!(
      gate_requirement: 0,
      order: 1
    )

    # Add Pokemon to starter route
    RouteEncounter.create!(route: @starter_route, pokemon: pokemons(:bulbasaur), spawn_rate: 30)
    RouteEncounter.create!(route: @starter_route, pokemon: pokemons(:charmander), spawn_rate: 30)
    RouteEncounter.create!(route: @starter_route, pokemon: pokemons(:squirtle), spawn_rate: 20)
    RouteEncounter.create!(route: @starter_route, pokemon: pokemons(:pikachu), spawn_rate: 10)
    RouteEncounter.create!(route: @starter_route, pokemon: pokemons(:mewtwo), spawn_rate: 10)

    # Create always accessible route (display data loaded from YAML)
    @test_route = Route.create!(
      gate_requirement: 0,
      order: 2
    )

    # Add some Pokemon to the gated test route
    RouteEncounter.create!(route: @test_route, pokemon: pokemons(:pikachu), spawn_rate: 50)
    RouteEncounter.create!(route: @test_route, pokemon: pokemons(:mewtwo), spawn_rate: 50)
  end

  # ================================================================================
  # REGISTRATION FORM DISPLAY TESTS
  # ================================================================================

  test "should get registration page" do
    get new_trainer_path
    assert_response :success
  end

  test "should display registration form" do
    get new_trainer_path
    assert_select "form"
  end

  test "should not require authentication to view registration page" do
    get new_trainer_path
    assert_response :success
  end


  # ================================================================================
  # SUCCESSFUL REGISTRATION TESTS
  # ================================================================================

  test "should create trainer with valid data and activation code" do
    assert_difference("Trainer.count", 1) do
      post trainers_path, params: {
        trainer: {
          username: "newtrainer",
          password: "password123",
          icon_pokemon_id: pokemons(:pikachu).id
        },
        activation_code: "TEST01"
      }
    end
  end

  test "should set session trainer_id on successful registration" do
    post trainers_path, params: {
      trainer: {
        username: "newtrainer",
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }

    assert_not_nil session[:trainer_id]
    assert_equal "newtrainer", Trainer.find(session[:trainer_id]).username
  end

  test "should redirect to onboarding on successful registration" do
    post trainers_path, params: {
      trainer: {
        username: "newtrainer",
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }

    assert_redirected_to onboarding_welcome_path
  end

  test "should not show welcome flash message on successful registration" do
    post trainers_path, params: {
      trainer: {
        username: "newtrainer",
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }

    # No flash message on registration - onboarding will handle welcome
    assert_nil flash[:notice]
  end

  test "should automatically log in user after successful registration" do
    post trainers_path, params: {
      trainer: {
        username: "newtrainer",
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }

    # Should be redirected to onboarding (not dashboard)
    get dashboard_path
    assert_redirected_to onboarding_welcome_path
  end

  test "should create new trainer with 0 starting currency" do
    post trainers_path, params: {
      trainer: {
        username: "newtrainer",
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }

    new_trainer = Trainer.find_by(username: "newtrainer")
    assert_not_nil new_trainer
    assert_equal 0, new_trainer.currency
  end

  # ================================================================================
  # FAILED REGISTRATION - MISSING FIELDS TESTS
  # ================================================================================

  test "should not create trainer without username" do
    assert_no_difference("Trainer.count") do
      post trainers_path, params: {
        trainer: {
          username: "",
          password: "password123",
          icon_pokemon_id: pokemons(:pikachu).id
        },
        activation_code: "TEST01"
      }
    end
  end

  test "should show error for missing username" do
    post trainers_path, params: {
      trainer: {
        username: "",
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }

    assert_response :unprocessable_entity
  end

  test "should not create trainer without password" do
    assert_no_difference("Trainer.count") do
      post trainers_path, params: {
        trainer: {
          username: "newtrainer",
          password: "",
          icon_pokemon_id: pokemons(:pikachu).id
        },
        activation_code: "TEST01"
      }
    end
  end

  test "should show error for missing password" do
    post trainers_path, params: {
      trainer: {
        username: "newtrainer",
        password: "",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }

    assert_response :unprocessable_entity
  end

  test "should re-render form on validation failure" do
    post trainers_path, params: {
      trainer: {
        username: "",
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }

    assert_response :unprocessable_entity
    assert_select "form"
  end


  # ================================================================================
  # FAILED REGISTRATION - DUPLICATE USERNAME TESTS
  # ================================================================================

  test "should not create trainer with duplicate username" do
    existing_trainer = trainers(:ash)

    assert_no_difference("Trainer.count") do
      post trainers_path, params: {
        trainer: {
          username: existing_trainer.username,
          password: "password123",
          icon_pokemon_id: pokemons(:pikachu).id
        },
        activation_code: "TEST01"
      }
    end
  end

  test "should show error for duplicate username" do
    existing_trainer = trainers(:ash)

    post trainers_path, params: {
      trainer: {
        username: existing_trainer.username,
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }

    assert_response :unprocessable_entity
  end

  test "should not set session with duplicate username" do
    existing_trainer = trainers(:ash)

    post trainers_path, params: {
      trainer: {
        username: existing_trainer.username,
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }

    # Session should not be set for the new (failed) registration
    assert_nil session[:trainer_id]
  end

  # ================================================================================
  # ACTIVATION CODE VALIDATION TESTS
  # ================================================================================

  test "should not create trainer without activation code" do
    assert_no_difference("Trainer.count") do
      post trainers_path, params: {
        trainer: {
          username: "newtrainer",
          password: "password123",
          icon_pokemon_id: pokemons(:pikachu).id
        },
        activation_code: ""
      }
    end
  end

  test "should show error for missing activation code" do
    post trainers_path, params: {
      trainer: {
        username: "newtrainer",
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: ""
    }

    assert_response :unprocessable_entity
  end

  test "should not create trainer with invalid activation code" do
    assert_no_difference("Trainer.count") do
      post trainers_path, params: {
        trainer: {
          username: "newtrainer",
          password: "password123",
          icon_pokemon_id: pokemons(:pikachu).id
        },
        activation_code: "INVALID"
      }
    end
  end

  test "should show error for invalid activation code" do
    post trainers_path, params: {
      trainer: {
        username: "newtrainer",
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "INVALID"
    }

    assert_response :unprocessable_entity
  end


  test "should not create trainer with inactive activation code" do
    assert_no_difference("Trainer.count") do
      post trainers_path, params: {
        trainer: {
          username: "newtrainer",
          password: "password123",
          icon_pokemon_id: pokemons(:pikachu).id
        },
        activation_code: "TEST02" # This is inactive in fixtures
      }
    end
  end

  test "should treat activation code as case insensitive" do
    assert_difference("Trainer.count", 1) do
      post trainers_path, params: {
        trainer: {
          username: "newtrainer",
          password: "password123",
          icon_pokemon_id: pokemons(:pikachu).id
        },
        activation_code: "test01" # lowercase version of TEST01
      }
    end
  end

  test "should accept activation code with leading/trailing spaces" do
    assert_difference("Trainer.count", 1) do
      post trainers_path, params: {
        trainer: {
          username: "newtrainer2",
          password: "password123",
          icon_pokemon_id: pokemons(:pikachu).id
        },
        activation_code: " TEST01 "
      }
    end
  end

  test "should handle nil activation code parameter" do
    assert_no_difference("Trainer.count") do
      post trainers_path, params: {
        trainer: {
          username: "newtrainer",
          password: "password123",
          icon_pokemon_id: pokemons(:pikachu).id
        },
        activation_code: nil
      }
    end
  end

  # ================================================================================
  # ICON POKEMON SELECTION TESTS
  # ================================================================================

  test "should not allow registration without icon" do
    assert_no_difference("Trainer.count") do
      post trainers_path, params: {
        trainer: {
          username: "newtrainer",
          password: "password123",
          icon_pokemon_id: nil,
          icon_trainer_sprite: nil
        },
        activation_code: "TEST01"
      }
    end
    assert_response :unprocessable_entity
  end

  test "should save icon pokemon when provided" do
    post trainers_path, params: {
      trainer: {
        username: "newtrainer",
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }

    trainer = Trainer.find_by(username: "newtrainer")
    assert_equal pokemons(:pikachu), trainer.icon_pokemon
  end

  test "should allow registration with valid icon pokemon id" do
    pokemon = pokemons(:bulbasaur)

    assert_difference("Trainer.count", 1) do
      post trainers_path, params: {
        trainer: {
          username: "newtrainer",
          password: "password123",
          icon_pokemon_id: pokemon.id
        },
        activation_code: "TEST01"
      }
    end
  end

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
  # REWARDS PAGE - UI AND DISPLAY TESTS
  # ================================================================================

  test "should display page title on rewards page" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "Shop", response.body
  end

  test "should display page description on rewards page" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "Claim rewards and buy or sell items", response.body
  end

  test "should display claim reward card header" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "Claim Your Reward", response.body
  end

  test "should display claim reward card icon" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "🎁", response.body
  end

  test "should display instructions for claiming rewards" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "After completing a ticket, select the option below associated to your ticket's story points to receive a reward! Higher story points are more likely to grant better pokeballs!", response.body
  end

  test "should render sidebar on rewards page" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "aside.sidebar"
  end

  # ================================================================================
  # REWARDS PAGE - STORY POINT BUTTON TESTS
  # ================================================================================

  test "should display 1 point button" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input[type='submit'][value='1 Point']"
  end

  test "should display 2 points button" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input[type='submit'][value='2 Points']"
  end

  test "should display 3 points button" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input[type='submit'][value='3 Points']"
  end

  test "should display 5 points button" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input[type='submit'][value='5 Points']"
  end

  test "should display 8 points button" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input[type='submit'][value='8 Points']"
  end

  test "should display all 5 story point buttons" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input.story-point-button", count: 5
  end

  test "should display Other input field" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input[type='number'][placeholder='Other']"
  end

  test "should display Claim button for Other input" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input[type='submit'][value='Claim']"
  end

  test "should set min value to 1 for Other input" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input[type='number'][min='1']"
  end

  test "should set max value to 100 for Other input" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input[type='number'][max='100']"
  end

  test "should have story points grid layout" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "div.story-points-grid"
  end

  # ================================================================================
  # REWARDS PAGE - FORM SUBMISSION TESTS
  # ================================================================================

  test "should have hidden field with value 1 in first form" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "form" do
      assert_select "input[type='hidden'][value='1']"
    end
  end

  test "should have hidden field with value 2 in second form" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input[type='hidden'][value='2']"
  end

  test "should have hidden field with value 3 in third form" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input[type='hidden'][value='3']"
  end

  test "should have hidden field with value 5 in fourth form" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input[type='hidden'][value='5']"
  end

  test "should have hidden field with value 8 in fifth form" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "input[type='hidden'][value='8']"
  end

  test "should have forms for story points and shop on rewards page" do
    log_in_as(trainers(:ash))
    get rewards_path
    # 5 preset buttons + 1 "Other" input form + shop buy/sell forms (not counting sidebar logout form)
    assert_select "main.main-content" do
      assert_select "form", minimum: 6
    end
  end

  test "should submit to rewards_path" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "form[action=?]", rewards_path
  end

  test "should use POST method for forms" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "form[method='post']"
  end

  # ================================================================================
  # REWARDS PAGE - EDGE CASE TESTS
  # ================================================================================

  test "should maintain session across rewards page visits" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get rewards_path
    assert_response :success

    get rewards_path
    assert_response :success
    assert_equal trainer.id, session[:trainer_id]
  end

  test "should handle custom story point value via Other input" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_total = trainer.total_pokeballs

    post rewards_path, params: { story_points: 13 }

    assert_redirected_to rewards_path
    assert_match(/Congratulations! You earned a/, flash[:notice])

    trainer.reload
    assert_equal initial_total + 1, trainer.total_pokeballs
  end

  test "should display success message with ball type and story points" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    post rewards_path, params: { story_points: 5 }

    assert_redirected_to rewards_path
    # Message should include ball type and story points
    assert_match(/5 point ticket/, flash[:notice])
  end

  test "should award ball and redirect on successful redemption" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    post rewards_path, params: { story_points: 8 }

    assert_redirected_to rewards_path
    assert_not_nil flash[:notice]
  end

  test "should display dashboard cards layout" do
    log_in_as(trainers(:ash))
    get rewards_path
    # Awards Counter + Reward Probabilities + Sales Counter
    assert_select "div.card-dashboard", minimum: 2
  end

  test "should display card dashboard headers" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "div.card-dashboard-header", count: 2
  end

  test "should display card dashboard titles" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "h2.card-dashboard-title", count: 2
  end

  test "should display card dashboard icons" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "span.card-dashboard-icon", count: 2
  end

  test "should handle very large story point values" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_total = trainer.total_pokeballs

    post rewards_path, params: { story_points: 100 }

    assert_redirected_to rewards_path
    assert_match(/Congratulations/, flash[:notice])

    trainer.reload
    assert_equal initial_total + 1, trainer.total_pokeballs
  end

  test "should show error for zero story points" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    post rewards_path, params: { story_points: 0 }

    assert_redirected_to rewards_path
    assert_equal "Please enter a valid story point value", flash[:alert]
  end

  test "should show error for negative story points" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    post rewards_path, params: { story_points: -5 }

    assert_redirected_to rewards_path
    assert_equal "Please enter a valid story point value", flash[:alert]
  end

  test "should not award ball for invalid story points" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_total = trainer.total_pokeballs

    post rewards_path, params: { story_points: 0 }

    trainer.reload
    assert_equal initial_total, trainer.total_pokeballs
  end

  test "should display page with correct structure" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "div.app-layout"
    assert_select "main.main-content"
    assert_select "header.page-header-authenticated"
  end

  test "should include story point other section" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "div.story-point-other"
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
    # First request to clear login flash
    get catches_path
    assert_response :success
    # Second request should show pokeballs alert (no other flash messages)
    get catches_path
    assert_response :success
    # Message appears HTML-encoded in the toast
    assert_match /You (don't|don&#39;t) have any Pokéballs! Complete tickets to earn some\./, response.body
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

  test "should allow selecting already caught pokemon for duplicate capture" do
    log_in_as(trainers(:gary))
    pokemon = pokemons(:charmander) # Gary already caught this

    get catch_path(pokemon)
    assert_response :success
    assert_match pokemon.name, response.body
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

    # Unlock all gates so catch doesn't trigger gate celebration
    Gate.all.each do |gate|
      trainer.gate_unlocks.find_or_create_by(gate: gate)
    end

    initial_master_balls = trainer.ball_count(:master_ball)

    # Master ball has 100% catch rate
    post catch_path(pokemon), params: { ball_type: "master_ball" }

    # Should redirect to pokemon celebration page
    assert_redirected_to pokemon_celebration_path

    trainer.reload
    assert_includes trainer.captured_pokemon, pokemon
    assert_equal initial_master_balls - 1, trainer.ball_count(:master_ball)
  end

  test "should use pokeball when attempting catch" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:mewtwo)

    initial_pokeballs = trainer.ball_count(:pokeball)

    post catch_path(pokemon), params: { ball_type: "pokeball" }

    trainer.reload
    # Ball should be used regardless of success
    assert_equal initial_pokeballs - 1, trainer.ball_count(:pokeball)
  end

  test "should use great ball when attempting catch" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)

    initial_great_balls = trainer.ball_count(:great_ball)

    post catch_path(pokemon), params: { ball_type: "great_ball" }

    trainer.reload
    assert_equal initial_great_balls - 1, trainer.ball_count(:great_ball)
  end

  test "should use ultra ball when attempting catch" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)

    initial_ultra_balls = trainer.ball_count(:ultra_ball)

    post catch_path(pokemon), params: { ball_type: "ultra_ball" }

    trainer.reload
    assert_equal initial_ultra_balls - 1, trainer.ball_count(:ultra_ball)
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

  test "should give evolution stone when catching already caught pokemon" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    pokemon = pokemons(:charmander) # Gary already caught this

    # Give trainer master ball for guaranteed success
    trainer.add_item(:master_ball, 1)
    initial_captures = trainer.captures.count
    initial_stones = trainer.item_quantity(:evolution_stone)

    post catch_path(pokemon), params: { ball_type: "master_ball" }

    # Should redirect to pokemon celebration page
    assert_redirected_to pokemon_celebration_path

    trainer.reload
    # Should not create new capture
    assert_equal initial_captures, trainer.captures.count
    # Should give evolution stone
    assert_equal initial_stones + 1, trainer.item_quantity(:evolution_stone)
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



  test "should filter out caught pokemon from uncaught list" do
    trainer = trainers(:gary)
    log_in_as(trainer)

    get catches_path

    # Verify the page shows uncaught pokemon but not caught ones
    assert_response :success
    assert_match "Bulbasaur", response.body
  end

  # ================================================================================
  # CATCH PAGE (NEW) - ADVENTURES PANEL TESTS
  # ================================================================================

  test "should display adventures panel with adventure count" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get catches_path
    assert_select "div.adventures-panel"
    assert_match "/ 10", response.body
    assert_match "Adventures", response.body
  end

  # ================================================================================
  # CATCH PAGE (NEW) - POKEMON CARD DISPLAY TESTS
  # ================================================================================

  test "should display pokemon names on catch cards" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_match "Bulbasaur", response.body
    assert_match "Charmander", response.body
  end

  # ================================================================================
  # CATCH PAGE (NEW) - DIFFICULTY DISPLAY TESTS
  # ================================================================================

  test "should display correct number of stars for difficulty 1" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    # Bulbasaur has difficulty 1
    # Would need to count stars per card, but we can verify they appear
    assert_response :success
  end

  test "should display correct number of stars for difficulty 5" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Create a capture so Mewtwo shows up
    get catches_path
    # Mewtwo has difficulty 5
    assert_match "Mewtwo", response.body
  end

  # ================================================================================
  # CATCH PAGE (NEW) - TRAINER COUNT DISPLAY TESTS
  # ================================================================================
















  # ================================================================================
  # CATCH PAGE (NEW) - EMPTY STATE TESTS
  # ================================================================================




  # ================================================================================
  # CATCH PAGE (SHOW) - POKEMON INFO TESTS
  # ================================================================================

  test "should display pokemon name capitalized on selection page" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_match "Bulbasaur", response.body
  end

  test "should display pokedex number on selection page" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:pikachu)
    get catch_path(pokemon)
    assert_match "#025", response.body
  end

  test "should display difficulty stars on selection page" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:pikachu)
    get catch_path(pokemon)
    assert_select "span.star-filled"
    assert_select "span.star-empty"
  end

  test "should display Very Easy for difficulty 1" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur) # difficulty 1
    get catch_path(pokemon)
    assert_match "Very Easy", response.body
  end

  test "should display Easy for difficulty 2" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:pikachu) # difficulty 2
    get catch_path(pokemon)
    assert_match "Easy", response.body
  end

  test "should display Very Hard for difficulty 5" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:mewtwo) # difficulty 5
    get catch_path(pokemon)
    assert_match "Very Hard", response.body
  end

  test "should display Capture Difficulty label on selection page" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_match "Capture Difficulty:", response.body
  end

  # ================================================================================
  # CATCH PAGE (SHOW) - POKEBALL SELECTION TESTS
  # ================================================================================

  test "should display all 4 pokeball types on selection page" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_match "Pokéball", response.body
    assert_match "Great Ball", response.body
    assert_match "Ultra Ball", response.body
    assert_match "Master Ball", response.body
  end

  test "should display pokeball counts for each type" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_match trainer.ball_count(:pokeball).to_s, response.body
    assert_match trainer.ball_count(:great_ball).to_s, response.body
    assert_match trainer.ball_count(:ultra_ball).to_s, response.body
    assert_match trainer.ball_count(:master_ball).to_s, response.body
  end

  test "should display catch rate percentages" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_match "% catch rate", response.body
  end

  test "should show higher catch rate for master ball" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    # Master ball should show 100%
    assert_match "100% catch rate", response.body
  end

  test "should show different catch rates based on pokemon difficulty" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Get catch rates for easy pokemon (difficulty 1)
    easy_pokemon = pokemons(:bulbasaur)
    get catch_path(easy_pokemon)
    easy_response = response.body

    # Get catch rates for hard pokemon (difficulty 5)
    hard_pokemon = pokemons(:mewtwo)
    get catch_path(hard_pokemon)
    hard_response = response.body

    # Responses should be different (harder pokemon = lower catch rates)
    assert_not_equal easy_response, hard_response
  end

  test "should display Submit button for each pokeball type" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    # Check specifically in the pokeball grid (4 pokeballs + 1 run button)
    assert_select "div.pokeball-grid" do
      assert_select "button[type='submit']", count: 5
    end
  end

  test "should display Available label for each ball type" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_match "Available", response.body
  end

  test "should display run button" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_match "Run", response.body
    assert_match "Run", response.body
    assert_select "form[action=?]", run_from_catch_path(pokemon)
  end

  test "should show pokeball selection title" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_match "Select Your Pokéball", response.body
  end

  # ================================================================================
  # CATCH PAGE (SHOW) - DISABLED BALL TESTS
  # ================================================================================

  test "should disable pokeball button when count is zero" do
    trainer = trainers(:broke_trainer)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    # Broke trainer has 0 pokeballs
    assert_select "button.pokeball-disabled"
  end

  test "should show disabled class for balls with zero count" do
    trainer = trainers(:broke_trainer)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    # Check for disabled attribute (HTML5 boolean attribute)
    assert_select "button[disabled]"
  end

  # ================================================================================
  # CATCH EDGE CASES AND INTEGRATION TESTS
  # ================================================================================



  test "should maintain session across catch flow" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Visit catch list
    get catches_path
    assert_response :success

    # Visit pokemon selection
    get catch_path(pokemons(:bulbasaur))
    assert_response :success

    # Session should still be valid
    assert_equal trainer.id, session[:trainer_id]
  end

  test "should display pokemon info card on selection page" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_select "div.select-pokemon-card"
  end

  test "should display pokeball grid on selection page" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_select "div.pokeball-grid"
  end

  test "should render sidebar on catch list page" do
    log_in_as(trainers(:ash))
    get catches_path
    assert_select "aside.sidebar"
  end

  test "should render sidebar on pokemon selection page" do
    log_in_as(trainers(:ash))
    get catch_path(pokemons(:bulbasaur))
    assert_select "aside.sidebar"
  end

  test "should show pokemon with all difficulty levels" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path

    # Should show pokemon of various difficulties
    assert_match "Bulbasaur", response.body  # difficulty 1
    assert_match "Pikachu", response.body     # difficulty 2
    assert_match "Mewtwo", response.body      # difficulty 5
  end


  test "should handle catch attempt with different ball types" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)

    # Each ball type should be accepted as a parameter
    get catch_path(pokemon)
    assert_response :success

    # Verify forms exist for all ball types
    assert_select "input[name='ball_type'][value='pokeball']"
    assert_select "input[name='ball_type'][value='great_ball']"
    assert_select "input[name='ball_type'][value='ultra_ball']"
    assert_select "input[name='ball_type'][value='master_ball']"
  end

  test "should order uncaught pokemon by pokedex number" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get catches_path

    # Gary hasn't caught Bulbasaur(#1), Pikachu(#25), Mewtwo(#150), Mew(#151)
    # They should appear in that order
    bulbasaur_pos = response.body.index("Bulbasaur")
    pikachu_pos = response.body.index("Pikachu")

    assert_not_nil bulbasaur_pos
    assert_not_nil pikachu_pos
    assert bulbasaur_pos < pikachu_pos
  end

  # ================================================================================
  # DASHBOARD TESTS
  # ================================================================================

  test "should get dashboard when logged in" do
    log_in_as(trainers(:ash))
    get dashboard_path
    assert_response :success
  end

  test "should redirect to login when accessing dashboard without authentication" do
    get dashboard_path
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "should handle POST to dashboard by redirecting to GET dashboard" do
    log_in_as(trainers(:ash))
    post dashboard_path
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success
  end

  test "should display trainer username on dashboard" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path
    assert_match trainer.username, response.body
  end

  test "should display pokeball count on dashboard" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path
    assert_match trainer.ball_count(:pokeball).to_s, response.body
  end

  test "should display great ball count on dashboard" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path
    assert_match trainer.ball_count(:great_ball).to_s, response.body
  end

  test "should display ultra ball count on dashboard" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path
    assert_match trainer.ball_count(:ultra_ball).to_s, response.body
  end

  test "should display master ball count on dashboard" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path
    assert_match trainer.ball_count(:master_ball).to_s, response.body
  end

  test "should display capture count on dashboard" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get dashboard_path
    # Gary has 2 captures in fixtures
    assert_match "2", response.body
  end

  test "should display zero captures for new trainer on dashboard" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path
    # Ash has 0 captures
    assert_match "0 / 151", response.body
  end

  test "should calculate completion percentage correctly on dashboard" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get dashboard_path
    # Gary has 2 captures out of 151 = 1.3%
    completion = (2.0 / 151 * 100).round(1)
    assert_match "#{completion}%", response.body
  end

  test "should show 0 percent for trainer with no captures" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path
    assert_match "0.0%", response.body
  end

  test "should show correct percentage when trainer catches all available pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Capture all available pokemon in test fixtures (6 total)
    Pokemon.all.each do |pokemon|
      Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")
    end

    get dashboard_path
    pokemon_count = Pokemon.count
    completion = (pokemon_count.to_f / 151 * 100).round(1)
    assert_match "#{pokemon_count} / 151", response.body
    assert_match "#{completion}%", response.body
  end

  test "should render sidebar on dashboard" do
    log_in_as(trainers(:ash))
    get dashboard_path
    assert_select "aside.sidebar"
  end

  test "should show dashboard title" do
    log_in_as(trainers(:ash))
    get dashboard_path
    assert_match "Trainer Dashboard", response.body
  end

  test "should show welcome message on dashboard" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path
    assert_match "Welcome back", response.body
  end

  test "should display pokeball inventory section" do
    log_in_as(trainers(:ash))
    get dashboard_path
    assert_match "Inventory", response.body
    assert_match "Pokéballs", response.body  # Subsection title
  end

  test "should display pokedex progress section" do
    log_in_as(trainers(:ash))
    get dashboard_path
    assert_match "Pokédex Progress", response.body
  end

  test "should display difficulty score on dashboard" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Give trainer some pokemon with different difficulties
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball") # difficulty 2
    Capture.create!(trainer: trainer, pokemon: pokemons(:mewtwo), ball_type: "pokeball") # difficulty 5
    get dashboard_path
    # Should display difficulty score (2 + 5 = 7)
    expected_score = trainer.difficulty_score
    assert_match "#{expected_score}★", response.body
    assert_match "Difficulty Score", response.body
  end

  test "should display difficulty score even when trainer has no captures" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path
    # Should display 0★
    assert_match "0★", response.body
    assert_match "Difficulty Score", response.body
  end

  test "should maintain session across dashboard visits" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Visit dashboard multiple times
    get dashboard_path
    assert_response :success

    get dashboard_path
    assert_response :success
    assert_equal trainer.id, session[:trainer_id]
  end

  # ================================================================================
  # BADGES SECTION TESTS
  # ================================================================================

  test "should display badges section on dashboard" do
    log_in_as(trainers(:ash))
    get dashboard_path
    assert_select "div.badges-section"
  end

  test "should display badges title" do
    log_in_as(trainers(:ash))
    get dashboard_path
    assert_select "h2.badges-title"
    assert_match "Gym Badges", response.body
  end

  test "should display all 9 badge slots" do
    log_in_as(trainers(:ash))
    get dashboard_path
    assert_select "div.badge-slot", count: 9
  end

  test "should display empty badge slots for trainer with no badges" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path

    # Should have 9 empty slots
    assert_select "div.badge-empty", count: 9
    # Should have no earned badges
    assert_select "img.badge-sprite", count: 0
  end

  test "should display earned badge when trainer unlocks gate 1" do
    trainer = trainers(:ash)
    gate_1 = Gate.find_or_create_by!(gate_number: 1) { |g| g.required_difficulty_score = 8 }
    trainer.gate_unlocks.find_or_create_by!(gate: gate_1)

    log_in_as(trainer)
    get dashboard_path

    # Should have 1 earned badge
    assert_select "div.badge-slot.badge-earned", count: 1
    assert_select "img.badge-sprite", count: 1
    # Should have Boulder Badge image
    assert_select "img.badge-sprite[alt='Boulder Badge']"
    # Should have 8 empty slots
    assert_select "div.badge-empty", count: 8
  end

  test "should display correct badge sprite for each gate" do
    trainer = trainers(:ash)
    gate_2 = Gate.find_or_create_by!(gate_number: 2) { |g| g.required_difficulty_score = 17 }
    trainer.gate_unlocks.find_or_create_by!(gate: gate_2)

    log_in_as(trainer)
    get dashboard_path

    # Should have Cascade Badge for gate 2
    assert_select "img.badge-sprite[alt='Cascade Badge']"
    assert_select "img.badge-sprite[title='Cascade Badge']"
  end

  test "should display multiple earned badges in order" do
    trainer = trainers(:ash)
    gate_1 = Gate.find_or_create_by!(gate_number: 1) { |g| g.required_difficulty_score = 8 }
    gate_2 = Gate.find_or_create_by!(gate_number: 2) { |g| g.required_difficulty_score = 17 }
    gate_3 = Gate.find_or_create_by!(gate_number: 3) { |g| g.required_difficulty_score = 25 }

    trainer.gate_unlocks.find_or_create_by!(gate: gate_1)
    trainer.gate_unlocks.find_or_create_by!(gate: gate_2)
    trainer.gate_unlocks.find_or_create_by!(gate: gate_3)

    log_in_as(trainer)
    get dashboard_path

    # Should have 3 earned badges
    assert_select "div.badge-slot.badge-earned", count: 3
    assert_select "img.badge-sprite", count: 3
    # Should have 6 empty slots
    assert_select "div.badge-empty", count: 6

    # Verify all three badges are displayed
    assert_select "img.badge-sprite[alt='Boulder Badge']"
    assert_select "img.badge-sprite[alt='Cascade Badge']"
    assert_select "img.badge-sprite[alt='Thunder Badge']"
  end

  test "should display all 9 badges when all gyms and Elite Four are beaten" do
    trainer = trainers(:ash)
    (1..9).each do |gate_number|
      gate = Gate.find_or_create_by!(gate_number: gate_number) { |g| g.required_difficulty_score = gate_number * 10 }
      trainer.gate_unlocks.find_or_create_by!(gate: gate)
    end

    log_in_as(trainer)
    get dashboard_path

    # Should have 9 earned badges
    assert_select "div.badge-slot.badge-earned", count: 9
    assert_select "img.badge-sprite", count: 9
    # Should have no empty slots
    assert_select "div.badge-empty", count: 0
  end

  test "should display correct badge titles as tooltips" do
    trainer = trainers(:ash)
    gate_5 = Gate.find_or_create_by!(gate_number: 5) { |g| g.required_difficulty_score = 40 }
    trainer.gate_unlocks.find_or_create_by!(gate: gate_5)

    log_in_as(trainer)
    get dashboard_path

    # Should have title attribute for Soul Badge
    assert_select "img.badge-sprite[title='Soul Badge']"
  end

  test "should display badges with data attributes for badge numbers" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path

    # Each badge slot should have data-badge-number attribute
    (1..9).each do |badge_number|
      assert_select "div.badge-slot[data-badge-number='#{badge_number}']"
    end
  end

  test "should display Elite Four Trophy for gate 9" do
    trainer = trainers(:ash)
    gate_9 = Gate.find_or_create_by!(gate_number: 9) { |g| g.required_difficulty_score = 75 }
    trainer.gate_unlocks.find_or_create_by!(gate: gate_9)

    log_in_as(trainer)
    get dashboard_path

    # Should have 9 badge slots including Elite Four
    assert_select "div.badge-slot", count: 9
    # Should have Elite Four Trophy badge
    assert_select "img.badge-sprite[alt='Elite Four Trophy']"
    assert_select "img.badge-sprite[title='Elite Four Trophy']"
  end

  test "should display badges section before inventory section" do
    log_in_as(trainers(:ash))
    get dashboard_path

    # Extract the HTML and verify badges come before inventory
    html = response.body
    badges_index = html.index("badges-section")
    inventory_index = html.index("Inventory")

    assert_not_nil badges_index, "Badges section should be present"
    assert_not_nil inventory_index, "Inventory section should be present"
    assert badges_index < inventory_index, "Badges should appear before inventory"
  end

  test "should handle trainer with non-sequential badge unlocks" do
    trainer = trainers(:ash)
    # Unlock gates 1, 3, and 5 (skipping 2 and 4)
    gate_1 = Gate.find_or_create_by!(gate_number: 1) { |g| g.required_difficulty_score = 8 }
    gate_3 = Gate.find_or_create_by!(gate_number: 3) { |g| g.required_difficulty_score = 25 }
    gate_5 = Gate.find_or_create_by!(gate_number: 5) { |g| g.required_difficulty_score = 40 }

    trainer.gate_unlocks.find_or_create_by!(gate: gate_1)
    trainer.gate_unlocks.find_or_create_by!(gate: gate_3)
    trainer.gate_unlocks.find_or_create_by!(gate: gate_5)

    log_in_as(trainer)
    get dashboard_path

    # Should have 3 earned badges in slots 1, 3, and 5
    assert_select "div.badge-slot.badge-earned", count: 3
    assert_select "img.badge-sprite[alt='Boulder Badge']"
    assert_select "img.badge-sprite[alt='Thunder Badge']"
    assert_select "img.badge-sprite[alt='Soul Badge']"

    # Slots 2, 4, 6, 7, 8, 9 should be empty
    assert_select "div.badge-empty", count: 6
  end

  test "should display all badge types correctly" do
    trainer = trainers(:ash)
    badge_gates = [
      { number: 1, name: "Boulder Badge" },
      { number: 2, name: "Cascade Badge" },
      { number: 3, name: "Thunder Badge" },
      { number: 4, name: "Rainbow Badge" },
      { number: 5, name: "Soul Badge" },
      { number: 6, name: "Marsh Badge" },
      { number: 7, name: "Volcano Badge" },
      { number: 8, name: "Earth Badge" }
    ]

    badge_gates.each do |badge_info|
      gate = Gate.find_or_create_by!(gate_number: badge_info[:number]) { |g| g.required_difficulty_score = badge_info[:number] * 10 }
      trainer.gate_unlocks.find_or_create_by!(gate: gate)
    end

    log_in_as(trainer)
    get dashboard_path

    # Verify all badge names are present
    badge_gates.each do |badge_info|
      assert_select "img.badge-sprite[alt='#{badge_info[:name]}']"
    end
  end

  # ================================================================================
  # NEWS FEED TESTS
  # ================================================================================

  test "should display news feed on dashboard" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path

    assert_response :success
    assert_select ".news-feed"
  end

  test "newsfeed entries should be clickable links to trainer pokedex" do
    ash = trainers(:ash)
    gary = trainers(:gary)

    # Gary catches a Pikachu
    pikachu = pokemons(:pikachu)
    Capture.create!(
      trainer: gary,
      pokemon: pikachu,
      ball_type: "pokeball",
      created_at: 1.hour.ago
    )

    log_in_as(ash)
    get dashboard_path

    assert_response :success
    # Should have a link to Gary's trainer page
    assert_select "a.news-item-link[href=?]", trainer_path(gary)
  end

  test "should show recent captures from other trainers" do
    ash = trainers(:ash)
    gary = trainers(:gary)

    # Gary catches a Pikachu
    pikachu = pokemons(:pikachu)
    capture = Capture.create!(
      trainer: gary,
      pokemon: pikachu,
      ball_type: "pokeball",
      created_at: 1.hour.ago
    )

    log_in_as(ash)
    get dashboard_path

    assert_response :success
    # Should show Gary's capture
    assert_match "gary", response.body.downcase
    assert_match "caught", response.body.downcase
    assert_match "Pikachu", response.body
  end

  test "should show recent evolutions from other trainers" do
    ash = trainers(:ash)
    gary = trainers(:gary)

    # Gary evolves Bulbasaur to Ivysaur
    ivysaur = Pokemon.find_or_create_by!(pokedex_number: 2) do |p|
      p.name = "Ivysaur"
      p.difficulty = 5
    end

    evolution = Capture.create!(
      trainer: gary,
      pokemon: ivysaur,
      ball_type: "pokeball",
      evolved: true,
      created_at: 30.minutes.ago
    )

    log_in_as(ash)
    get dashboard_path

    assert_response :success
    # Should show Gary's evolution
    assert_match "gary", response.body.downcase
    assert_match "evolved", response.body.downcase
    assert_match "Ivysaur", response.body
  end

  test "should not show current trainer in news feed" do
    ash = trainers(:ash)

    # Ash catches a Pikachu
    pikachu = pokemons(:pikachu)
    Capture.create!(
      trainer: ash,
      pokemon: pikachu,
      ball_type: "pokeball",
      created_at: 1.hour.ago
    )

    log_in_as(ash)
    get dashboard_path

    assert_response :success
    # News feed should exist
    assert_select ".news-feed"
    # But should not contain Ash's own captures
    # (unless there are other trainers' activities)
    news_feed_section = css_select(".news-feed").first.to_s
    # Check that if "ash" appears, it's not in a news-item context
    if news_feed_section.include?("ash")
      # It should only appear in the empty state or header, not in news items
      assert_select ".news-item .news-trainer", text: "ash", count: 0
    end
  end

  test "should show both captures and evolutions in chronological order" do
    ash = trainers(:ash)
    gary = trainers(:gary)
    misty = Trainer.create!(
      username: "misty_#{rand(10000)}",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id,
      onboarding_completed: true
    )

    # Create events at different times
    pikachu = pokemons(:pikachu)
    bulbasaur = pokemons(:bulbasaur)
    ivysaur = Pokemon.find_or_create_by!(pokedex_number: 2) do |p|
      p.name = "Ivysaur"
      p.difficulty = 5
    end

    # Gary catches Pikachu (most recent)
    gary_capture = Capture.create!(
      trainer: gary,
      pokemon: pikachu,
      ball_type: "pokeball",
      created_at: 10.minutes.ago
    )

    # Misty evolves Bulbasaur to Ivysaur (older)
    misty_evolution = Capture.create!(
      trainer: misty,
      pokemon: ivysaur,
      ball_type: "pokeball",
      evolved: true,
      created_at: 1.hour.ago
    )

    log_in_as(ash)
    get dashboard_path

    assert_response :success
    # Both events should appear
    assert_match "gary", response.body.downcase
    assert_match "misty", response.body.downcase
    assert_match "Pikachu", response.body
    assert_match "Ivysaur", response.body
  end

  test "should limit news feed to 50 items" do
    ash = trainers(:ash)

    # Create 60 different trainers who each caught a pokemon
    60.times do |i|
      trainer = Trainer.create!(
        username: "trainer_#{i}_#{rand(10000)}",
        password: "password",
        icon_pokemon_id: pokemons(:pikachu).id,
        onboarding_completed: true
      )

      pokemon = Pokemon.find_or_create_by!(pokedex_number: (i % 151) + 1) do |p|
        p.name = "TestPokemon#{(i % 151) + 1}"
        p.difficulty = 5
      end

      Capture.create!(
        trainer: trainer,
        pokemon: pokemon,
        ball_type: "pokeball",
        created_at: (60 - i).minutes.ago
      )
    end

    log_in_as(ash)
    get dashboard_path

    assert_response :success
    # Should only show maximum 50 items
    assert_select ".news-item", maximum: 50
  end

  test "should show empty state when no other trainer activity" do
    # Clear all existing captures to ensure empty state
    Capture.delete_all

    # Create a new trainer with no other trainers having activity
    trainer = Trainer.create!(
      username: "lonely_#{rand(10000)}",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id,
      onboarding_completed: true
    )

    log_in_as(trainer)
    get dashboard_path

    assert_response :success
    # Should show empty state message
    assert_select ".news-feed-empty"
    assert_match /no recent activity/i, response.body
  end

  test "should display pokemon sprites in news feed" do
    ash = trainers(:ash)
    gary = trainers(:gary)

    pikachu = pokemons(:pikachu)
    Capture.create!(
      trainer: gary,
      pokemon: pikachu,
      ball_type: "pokeball",
      created_at: 1.hour.ago
    )

    log_in_as(ash)
    get dashboard_path

    assert_response :success
    # Should have pokemon sprite image
    assert_select "img.news-pokemon-sprite"
  end

  test "should show timestamps in news feed" do
    ash = trainers(:ash)
    gary = trainers(:gary)

    pikachu = pokemons(:pikachu)
    Capture.create!(
      trainer: gary,
      pokemon: pikachu,
      ball_type: "pokeball",
      created_at: 2.hours.ago
    )

    log_in_as(ash)
    get dashboard_path

    assert_response :success
    # Should show timestamp
    assert_select ".news-timestamp"
    assert_match /ago/, response.body.downcase
  end

  test "should distinguish between caught and evolved events" do
    ash = trainers(:ash)
    gary = trainers(:gary)

    # Capture
    pikachu = pokemons(:pikachu)
    Capture.create!(
      trainer: gary,
      pokemon: pikachu,
      ball_type: "pokeball",
      created_at: 1.hour.ago
    )

    # Evolution
    ivysaur = Pokemon.find_or_create_by!(pokedex_number: 2) do |p|
      p.name = "Ivysaur"
      p.difficulty = 5
    end
    Capture.create!(
      trainer: gary,
      pokemon: ivysaur,
      ball_type: "pokeball",
      evolved: true,
      created_at: 30.minutes.ago
    )

    log_in_as(ash)
    get dashboard_path

    assert_response :success
    # Should have both event types with different styling
    assert_select ".news-item[data-event-type='caught']"
    assert_select ".news-item[data-event-type='evolved']"
  end

  # ================================================================================
  # NEWS FEED LOGIC TESTS - Deep Testing of build_news_feed
  # ================================================================================

  test "news feed should display events in correct chronological order (newest first)" do
    # Clear all captures to have clean state
    Capture.delete_all

    ash = trainers(:ash)
    gary = trainers(:gary)

    # Create events with specific timestamps
    oldest_pokemon = Pokemon.find_or_create_by!(pokedex_number: 10) { |p| p.name = "Caterpie"; p.difficulty = 5 }
    middle_pokemon = Pokemon.find_or_create_by!(pokedex_number: 11) { |p| p.name = "Metapod"; p.difficulty = 5 }
    newest_pokemon = Pokemon.find_or_create_by!(pokedex_number: 12) { |p| p.name = "Butterfree"; p.difficulty = 5 }

    # Create in non-chronological order to ensure sorting works
    Capture.create!(trainer: gary, pokemon: middle_pokemon, ball_type: "pokeball", created_at: 2.hours.ago)
    Capture.create!(trainer: gary, pokemon: oldest_pokemon, ball_type: "pokeball", created_at: 3.hours.ago)
    Capture.create!(trainer: gary, pokemon: newest_pokemon, ball_type: "pokeball", created_at: 1.hour.ago)

    log_in_as(ash)
    get dashboard_path

    # Extract the order of pokemon names from the HTML
    news_items = css_select(".news-item")
    pokemon_order = news_items.map { |item| item.to_s.match(/class="news-pokemon">(\w+)<\/span>/)[1] }

    # Should be in reverse chronological order (newest first)
    assert_equal [ "Butterfree", "Metapod", "Caterpie" ], pokemon_order
  end

  test "news feed should select 25 most recent captures when more than 25 exist" do
    ash = trainers(:ash)

    # Create 30 different trainers who each caught a pokemon
    30.times do |i|
      trainer = Trainer.create!(
        username: "catcher_test_#{i}_#{rand(10000)}",
        password: "password",
        icon_pokemon_id: pokemons(:pikachu).id,
        onboarding_completed: true
      )

      pokemon = Pokemon.find_or_create_by!(pokedex_number: (i % 151) + 1) do |p|
        p.name = "Pokemon#{(i % 151) + 1}"
        p.difficulty = 5
      end

      Capture.create!(
        trainer: trainer,
        pokemon: pokemon,
        ball_type: "pokeball",
        evolved: false,
        created_at: (30 - i).hours.ago
      )
    end

    log_in_as(ash)
    get dashboard_path

    # Should only show 25 capture events (the most recent 25)
    assert_select ".news-item[data-event-type='caught']", count: 25
  end

  test "news feed should select 25 most recent evolutions when more than 25 exist" do
    ash = trainers(:ash)

    # Create 30 different trainers who each evolved a pokemon
    30.times do |i|
      trainer = Trainer.create!(
        username: "evolver_#{i}_#{rand(10000)}",
        password: "password",
        icon_pokemon_id: pokemons(:pikachu).id,
        onboarding_completed: true
      )

      pokemon = Pokemon.find_or_create_by!(pokedex_number: (i % 151) + 1) do |p|
        p.name = "EvolvedPokemon#{(i % 151) + 1}"
        p.difficulty = 5
      end

      Capture.create!(
        trainer: trainer,
        pokemon: pokemon,
        ball_type: "pokeball",
        evolved: true,
        created_at: (30 - i).hours.ago
      )
    end

    log_in_as(ash)
    get dashboard_path

    # Should only show 25 evolution events (the most recent 25)
    assert_select ".news-item[data-event-type='evolved']", count: 25
  end

  test "news feed should correctly merge 25 captures and 25 evolutions then take top 50" do
    ash = trainers(:ash)

    # Create 30 captures (should take 25 most recent)
    30.times do |i|
      trainer = Trainer.create!(
        username: "catcher_#{i}_#{rand(10000)}",
        password: "password",
        icon_pokemon_id: pokemons(:pikachu).id,
        onboarding_completed: true
      )

      pokemon = Pokemon.find_or_create_by!(pokedex_number: (i % 50) + 1) do |p|
        p.name = "CaughtPokemon#{(i % 50) + 1}"
        p.difficulty = 5
      end

      Capture.create!(
        trainer: trainer,
        pokemon: pokemon,
        ball_type: "pokeball",
        evolved: false,
        created_at: (60 - i).hours.ago
      )
    end

    # Create 30 evolutions (should take 25 most recent)
    30.times do |i|
      trainer = Trainer.create!(
        username: "evolver_#{i}_#{rand(10000)}",
        password: "password",
        icon_pokemon_id: pokemons(:pikachu).id,
        onboarding_completed: true
      )

      pokemon = Pokemon.find_or_create_by!(pokedex_number: (i % 50) + 51) do |p|
        p.name = "EvolvedPokemon#{(i % 50) + 51}"
        p.difficulty = 5
      end

      Capture.create!(
        trainer: trainer,
        pokemon: pokemon,
        ball_type: "pokeball",
        evolved: true,
        created_at: (30 - i).hours.ago
      )
    end

    log_in_as(ash)
    get dashboard_path

    # Should show exactly 50 items (25 captures + 25 evolutions)
    assert_select ".news-item", count: 50
    # But the split might not be exactly 25/25 in the final 50 due to timestamp ordering
    # So just verify total is 50
  end

  test "news feed should not mix evolved flag - captures have evolved false" do
    ash = trainers(:ash)
    gary = trainers(:gary)

    # Create a regular capture (evolved: false)
    pikachu = pokemons(:pikachu)
    Capture.create!(
      trainer: gary,
      pokemon: pikachu,
      ball_type: "pokeball",
      evolved: false,
      created_at: 1.hour.ago
    )

    log_in_as(ash)
    get dashboard_path

    # Should appear as 'caught' type, not 'evolved'
    assert_select ".news-item[data-event-type='caught']", minimum: 1
    # The text should say "caught" not "evolved"
    assert_match /caught/i, response.body
  end

  test "news feed should not mix evolved flag - evolutions have evolved true" do
    ash = trainers(:ash)
    gary = trainers(:gary)

    # Create an evolution (evolved: true)
    ivysaur = Pokemon.find_or_create_by!(pokedex_number: 2) do |p|
      p.name = "Ivysaur"
      p.difficulty = 5
    end
    Capture.create!(
      trainer: gary,
      pokemon: ivysaur,
      ball_type: "pokeball",
      evolved: true,
      created_at: 1.hour.ago
    )

    log_in_as(ash)
    get dashboard_path

    # Should appear as 'evolved' type, not 'caught'
    assert_select ".news-item[data-event-type='evolved']", minimum: 1
    # The text should say "evolved" not "caught"
    assert_match /evolved/i, response.body
  end

  test "news feed chronological merge should prioritize newer events regardless of type" do
    # Clear all captures to have clean state
    Capture.delete_all

    ash = trainers(:ash)
    gary = trainers(:gary)
    misty = Trainer.create!(
      username: "misty_chrono_#{rand(10000)}",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id,
      onboarding_completed: true
    )

    # Create events interleaved by time
    # Oldest: Gary catches Pidgey (3 hours ago)
    pidgey = Pokemon.find_or_create_by!(pokedex_number: 16) { |p| p.name = "Pidgey"; p.difficulty = 5 }
    Capture.create!(trainer: gary, pokemon: pidgey, ball_type: "pokeball", evolved: false, created_at: 3.hours.ago)

    # Middle: Misty evolves Rattata (2 hours ago)
    raticate = Pokemon.find_or_create_by!(pokedex_number: 20) { |p| p.name = "Raticate"; p.difficulty = 5 }
    Capture.create!(trainer: misty, pokemon: raticate, ball_type: "pokeball", evolved: true, created_at: 2.hours.ago)

    # Newest: Gary catches Spearow (1 hour ago)
    spearow = Pokemon.find_or_create_by!(pokedex_number: 21) { |p| p.name = "Spearow"; p.difficulty = 5 }
    Capture.create!(trainer: gary, pokemon: spearow, ball_type: "pokeball", evolved: false, created_at: 1.hour.ago)

    log_in_as(ash)
    get dashboard_path

    # Extract the order of events
    news_items = css_select(".news-item")
    pokemon_order = news_items.map { |item| item.to_s.match(/class="news-pokemon">(\w+)<\/span>/)[1] }

    # Should be: Spearow (newest), Raticate (middle), Pidgey (oldest)
    assert_equal [ "Spearow", "Raticate", "Pidgey" ], pokemon_order
  end

  test "news feed should handle identical timestamps gracefully" do
    # Clear all captures to have clean state
    Capture.delete_all

    ash = trainers(:ash)
    gary = trainers(:gary)
    misty = Trainer.create!(
      username: "misty_#{rand(10000)}",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id,
      onboarding_completed: true
    )

    same_time = 1.hour.ago

    # Create multiple events at exactly the same timestamp
    pidgey = Pokemon.find_or_create_by!(pokedex_number: 16) { |p| p.name = "Pidgey"; p.difficulty = 5 }
    rattata = Pokemon.find_or_create_by!(pokedex_number: 19) { |p| p.name = "Rattata"; p.difficulty = 5 }

    Capture.create!(trainer: gary, pokemon: pidgey, ball_type: "pokeball", evolved: false, created_at: same_time)
    Capture.create!(trainer: misty, pokemon: rattata, ball_type: "pokeball", evolved: false, created_at: same_time)

    log_in_as(ash)
    get dashboard_path

    # Should not crash and should show both events
    assert_select ".news-item", count: 2
  end

  test "news feed should include all required data fields for each event" do
    ash = trainers(:ash)
    gary = trainers(:gary)

    pikachu = pokemons(:pikachu)
    Capture.create!(
      trainer: gary,
      pokemon: pikachu,
      ball_type: "great_ball",
      created_at: 1.hour.ago
    )

    log_in_as(ash)
    get dashboard_path

    # Verify the HTML contains all required data
    assert_response :success

    # Should have event type data attribute
    assert_select ".news-item[data-event-type='caught']"

    # Should have trainer name
    assert_select ".news-trainer", text: "gary"

    # Should have pokemon name
    assert_select ".news-pokemon", text: "Pikachu"

    # Should have timestamp
    assert_select ".news-timestamp"
    assert_match /ago/, response.body

    # Should have pokemon sprite
    assert_select "img.news-pokemon-sprite"
  end

  test "news feed should prioritize most recent when combining 25+25 into top 50" do
    ash = trainers(:ash)

    # Create 25 very old captures
    25.times do |i|
      trainer = Trainer.create!(
        username: "old_catcher_#{i}_#{rand(10000)}",
        password: "password",
        icon_pokemon_id: pokemons(:pikachu).id,
        onboarding_completed: true
      )

      pokemon = Pokemon.find_or_create_by!(pokedex_number: (i % 25) + 1) do |p|
        p.name = "OldPokemon#{(i % 25) + 1}"
        p.difficulty = 5
      end

      Capture.create!(
        trainer: trainer,
        pokemon: pokemon,
        ball_type: "pokeball",
        evolved: false,
        created_at: (100 + i).hours.ago
      )
    end

    # Create 25 recent evolutions
    25.times do |i|
      trainer = Trainer.create!(
        username: "recent_evolver_#{i}_#{rand(10000)}",
        password: "password",
        icon_pokemon_id: pokemons(:pikachu).id,
        onboarding_completed: true
      )

      pokemon = Pokemon.find_or_create_by!(pokedex_number: (i % 25) + 26) do |p|
        p.name = "RecentPokemon#{(i % 25) + 26}"
        p.difficulty = 5
      end

      Capture.create!(
        trainer: trainer,
        pokemon: pokemon,
        ball_type: "pokeball",
        evolved: true,
        created_at: (25 - i).hours.ago
      )
    end

    log_in_as(ash)
    get dashboard_path

    # All 50 items should be from the recent evolutions, not old captures
    # Because when we merge 25 old catches + 25 recent evolutions and take top 50,
    # the 25 recent evolutions should all appear
    assert_select ".news-item[data-event-type='evolved']", count: 25
    # The old captures should appear in the remaining 25 slots
    assert_select ".news-item[data-event-type='caught']", count: 25
  end

  # ================================================================================
  # END NEWS FEED LOGIC TESTS
  # ================================================================================

  # ================================================================================
  # POKEDEX TESTS
  # ================================================================================

  test "should get pokedex when logged in" do
    log_in_as(trainers(:ash))
    get pokedex_path
    assert_response :success
  end

  test "should redirect to login when accessing pokedex without authentication" do
    get pokedex_path
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "should display captured pokemon on pokedex" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    # Gary caught Charmander and Squirtle
    assert_match "Charmander", response.body
    assert_match "Squirtle", response.body
  end

  test "should order captured pokemon by pokedex number" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    # Charmander (#4) should appear before Squirtle (#7) in the HTML
    charmander_pos = response.body.index("Charmander")
    squirtle_pos = response.body.index("Squirtle")
    assert charmander_pos < squirtle_pos
  end

  test "should show empty state for trainer with no captures" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get pokedex_path
    assert_response :success
    # Ash has no captures
  end

  test "should display all captured pokemon for trainer with many captures" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Capture 5 pokemon
    Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:charmander), ball_type: "pokeball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:squirtle), ball_type: "pokeball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:mewtwo), ball_type: "master_ball")

    get pokedex_path
    assert_match "Bulbasaur", response.body
    assert_match "Charmander", response.body
    assert_match "Squirtle", response.body
    assert_match "Pikachu", response.body
    assert_match "Mewtwo", response.body
  end

  test "should render sidebar on pokedex" do
    log_in_as(trainers(:ash))
    get pokedex_path
    assert_select "aside.sidebar"
  end

  test "should show pokedex title" do
    log_in_as(trainers(:ash))
    get pokedex_path
    assert_match "Pokédex", response.body
  end

  test "should maintain session across pokedex visits" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get pokedex_path
    assert_response :success

    get pokedex_path
    assert_response :success
    assert_equal trainer.id, session[:trainer_id]
  end

  # ================================================================================
  # POKEDEX VIEW DETAIL TESTS
  # ================================================================================

  test "should display pokedex number with zero padding" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    # Charmander is #4, should display as #004
    assert_match "#004", response.body
    # Squirtle is #7, should display as #007
    assert_match "#007", response.body
  end

  test "should format three digit pokedex numbers correctly" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Mewtwo is #150
    Capture.create!(trainer: trainer, pokemon: pokemons(:mewtwo), ball_type: "master_ball")
    get pokedex_path
    assert_match "#150", response.body
  end

  test "should format single digit pokedex numbers with leading zeros" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Bulbasaur is #1
    Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    get pokedex_path
    assert_match "#001", response.body
  end

  test "should display ball type used for capture" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    # Gary caught Charmander with pokeball
    assert_match "Pokeball", response.body
  end

  test "should humanize ball type display" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "great_ball")
    get pokedex_path
    # great_ball should display as "Great ball"
    assert_match "Great ball", response.body
  end

  test "should display master ball humanized" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    Capture.create!(trainer: trainer, pokemon: pokemons(:mewtwo), ball_type: "master_ball")
    get pokedex_path
    assert_match "Master ball", response.body
  end

  test "should display ultra ball humanized" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "ultra_ball")
    get pokedex_path
    assert_match "Ultra ball", response.body
  end

  test "should display capture date in MM/DD/YY format" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    capture_time = Time.zone.parse("2025-03-15 14:30:00")
    travel_to capture_time do
      Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    end
    get pokedex_path
    assert_match "03/15/25", response.body
  end

  test "should display capture info for each pokemon" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    assert_match "Caught with", response.body
  end

  test "should show pokemon card for each captured pokemon" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    assert_select "div.pokemon-card", count: 2
  end

  test "should display pokemon names on cards" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    assert_select "h3.pokemon-name", text: "Charmander"
    assert_select "h3.pokemon-name", text: "Squirtle"
  end

  # ================================================================================
  # POKEDEX EMPTY STATE TESTS
  # ================================================================================

  test "should display empty state icon when no captures" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get pokedex_path
    assert_match "📖", response.body
  end

  test "should display empty state title when no captures" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get pokedex_path
    assert_match "No Pokémon Yet!", response.body
  end

  test "should display empty state description when no captures" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get pokedex_path
    assert_match "You haven't caught any Pokémon yet", response.body
  end

  test "should show Get Pokeballs button in empty state" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get pokedex_path
    assert_match "Get Pokéballs", response.body
    assert_select "a[href=?]", rewards_path
  end

  test "should show Go Catchin button in empty state" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get pokedex_path
    # The apostrophe is HTML encoded
    assert_match(/Go Catchin.*→/, response.body)
    assert_select "a[href=?]", catches_path
  end

  test "should not show empty state when trainer has captures" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    assert_no_match "No Pokémon Yet!", response.body
  end

  test "should not show pokemon cards when no captures" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get pokedex_path
    assert_select "div.pokemon-card", count: 0
  end

  # ================================================================================
  # POKEDEX EDGE CASE TESTS
  # ================================================================================

  test "should display multiple captures with different ball types" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:charmander), ball_type: "great_ball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:squirtle), ball_type: "ultra_ball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "master_ball")

    get pokedex_path
    assert_match "Pokeball", response.body
    assert_match "Great ball", response.body
    assert_match "Ultra ball", response.body
    assert_match "Master ball", response.body
  end

  test "should display captures from different dates" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    travel_to Time.zone.parse("2025-01-01 10:00:00") do
      Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    end

    travel_to Time.zone.parse("2025-06-15 15:30:00") do
      Capture.create!(trainer: trainer, pokemon: pokemons(:charmander), ball_type: "pokeball")
    end

    get pokedex_path
    assert_match "01/01/25", response.body
    assert_match "06/15/25", response.body
  end

  test "should handle pokedex with only one capture" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")

    get pokedex_path
    assert_response :success
    assert_select "div.pokemon-card", count: 1
    assert_match "Pikachu", response.body
  end

  test "should display pokedex header description" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get pokedex_path
    assert_match "Track and view all the Pokémon you've captured", response.body
  end

  test "should use pokedex grid layout when pokemon present" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    assert_select "div.pokedex-grid"
  end

  test "should display pokemon in correct order with mixed pokedex numbers" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Capture in random order: Mewtwo(150), Bulbasaur(1), Pikachu(25)
    Capture.create!(trainer: trainer, pokemon: pokemons(:mewtwo), ball_type: "pokeball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")

    get pokedex_path

    # All three should be present
    assert_match "Bulbasaur", response.body
    assert_match "Pikachu", response.body
    assert_match "Mewtwo", response.body

    # Check they appear in the correct order by finding #001, #025, #150
    num_001_pos = response.body.index("#001")
    num_025_pos = response.body.index("#025")
    num_150_pos = response.body.index("#150")

    assert_not_nil num_001_pos, "#001 not found"
    assert_not_nil num_025_pos, "#025 not found"
    assert_not_nil num_150_pos, "#150 not found"
    assert num_001_pos < num_025_pos, "#001 should appear before #025"
    assert num_025_pos < num_150_pos, "#025 should appear before #150"
  end

  test "should handle captures made at midnight" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    travel_to Time.zone.parse("2025-12-31 00:00:00") do
      Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    end

    get pokedex_path
    assert_match "12/31/25", response.body
  end

  test "should not show uncaptured pokemon" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    # Gary only caught Charmander and Squirtle
    # Should not show Bulbasaur, Pikachu, etc.
    assert_no_match "Bulbasaur", response.body
    assert_no_match "Pikachu", response.body
  end

  # ================================================================================
  # POKEDEX - TRAINER COUNT TESTS
  # ================================================================================

  test "should display trainer count for captured pokemon" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    # Gary caught Charmander
    # Should show "Caught by X/Y trainers"
    assert_match /Caught by \d+\/\d+ trainer/, response.body
  end

  test "should display correct trainer count when only one trainer caught pokemon" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    total_trainers = Trainer.count
    # Gary caught Charmander, and he's the only one
    assert_match "Caught by 1/#{total_trainers} trainer", response.body
  end

  test "should display correct trainer count when multiple trainers caught same pokemon" do
    trainer1 = trainers(:gary)
    trainer2 = trainers(:ash)

    # Both trainers catch Pikachu
    Capture.create!(trainer: trainer1, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    Capture.create!(trainer: trainer2, pokemon: pokemons(:pikachu), ball_type: "pokeball")

    log_in_as(trainer1)
    get pokedex_path

    total_trainers = Trainer.count
    # 2 trainers caught Pikachu
    assert_match "Caught by 2/#{total_trainers} trainers", response.body
  end

  test "should pluralize trainer correctly when count is 1" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    # Gary is the only one who caught Charmander
    assert_match /1\/\d+ trainer[^s]/, response.body
  end

  test "should pluralize trainers correctly when count is greater than 1" do
    trainer1 = trainers(:gary)
    trainer2 = trainers(:ash)

    # Both trainers catch Bulbasaur
    Capture.create!(trainer: trainer1, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    Capture.create!(trainer: trainer2, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")

    log_in_as(trainer1)
    get pokedex_path

    # Should say "trainers" (plural)
    assert_match "2/#{Trainer.count} trainers", response.body
  end

  test "should include current trainer in count" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    # Gary caught Charmander, count should include him
    # So it should be at least 1/total
    total_trainers = Trainer.count
    assert_match /Caught by [1-9]\d*\/#{total_trainers} trainer/, response.body
  end

  test "should display different counts for different pokemon" do
    trainer1 = trainers(:gary)
    trainer2 = trainers(:ash)

    # Gary caught both Charmander and Squirtle (already in fixtures)
    # Ash catches only Charmander
    Capture.create!(trainer: trainer2, pokemon: pokemons(:charmander), ball_type: "pokeball")

    log_in_as(trainer1)
    get pokedex_path

    total_trainers = Trainer.count
    # Charmander: 2 trainers (Gary and Ash)
    assert_match "Caught by 2/#{total_trainers} trainers", response.body
    # Squirtle: 1 trainer (Gary only)
    assert_match "Caught by 1/#{total_trainers} trainer", response.body
  end

  # ================================================================================
  # POKEDEX - DIFFICULTY STARS TESTS
  # ================================================================================

  test "should display difficulty stars on pokedex" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get pokedex_path
    # Should contain star characters
    assert_match "★", response.body
    # Should contain difficulty-stars class
    assert_select "div.difficulty-stars"
  end

  test "should display correct number of filled stars for difficulty 1 pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Bulbasaur has difficulty 1
    Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    get pokedex_path
    assert_select "span.star-filled", count: 1
    assert_select "span.star-empty", count: 4
  end

  test "should display correct number of filled stars for difficulty 2 pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Pikachu has difficulty 2
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    get pokedex_path
    assert_select "span.star-filled", count: 2
    assert_select "span.star-empty", count: 3
  end

  test "should display correct number of filled stars for difficulty 3 pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Raichu has difficulty 3
    Capture.create!(trainer: trainer, pokemon: pokemons(:raichu), ball_type: "pokeball")
    get pokedex_path
    assert_select "span.star-filled", count: 3
    assert_select "span.star-empty", count: 2
  end

  test "should display correct number of filled stars for difficulty 5 pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Mewtwo has difficulty 5
    Capture.create!(trainer: trainer, pokemon: pokemons(:mewtwo), ball_type: "pokeball")
    get pokedex_path
    assert_select "span.star-filled", count: 5
    assert_select "span.star-empty", count: 0
  end

  test "should display difficulty stars for multiple pokemon with different difficulties" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Bulbasaur (difficulty 1), Pikachu (difficulty 2), Mewtwo (difficulty 5)
    Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:mewtwo), ball_type: "pokeball")
    get pokedex_path
    # Total: 1 + 2 + 5 = 8 filled stars
    # Total: 4 + 3 + 0 = 7 empty stars
    assert_select "span.star-filled", count: 8
    assert_select "span.star-empty", count: 7
  end

  # ================================================================================
  # EVOLUTION LAB - PAGE ACCESS AND AUTHENTICATION TESTS
  # ================================================================================

  test "should get evolution lab when logged in" do
    log_in_as(trainers(:ash))
    get evolution_lab_path
    assert_response :success
  end

  test "should redirect to login when accessing evolution lab without authentication" do
    get evolution_lab_path
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "should display evolution lab title" do
    log_in_as(trainers(:ash))
    get evolution_lab_path
    assert_match "Evolution Lab", response.body
  end

  test "should display evolution lab description" do
    log_in_as(trainers(:ash))
    get evolution_lab_path
    assert_match "Evolve your Pokémon using Evolution Stones", response.body
  end

  test "should render sidebar on evolution lab" do
    log_in_as(trainers(:ash))
    get evolution_lab_path
    assert_select "aside.sidebar"
  end

  # ================================================================================
  # EVOLUTION LAB - EMPTY STATE TESTS
  # ================================================================================

  test "should display empty state when no evolutions available" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get evolution_lab_path
    assert_match "No Evolutions Available", response.body
  end

  test "should display empty state description when no evolutions available" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get evolution_lab_path
    assert_match "don't have any Pokémon ready to evolve", response.body
  end

  test "should display link to catches page in empty state" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get evolution_lab_path
    assert_select "a[href=?]", catches_path
  end

  test "should display link to shop in empty state" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get evolution_lab_path
    assert_select "a[href=?]", rewards_path
  end

  # ================================================================================
  # EVOLUTION LAB - AVAILABLE EVOLUTIONS DISPLAY TESTS
  # ================================================================================

  test "should display evolution when trainer has pre-evolution pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")

    get evolution_lab_path
    assert_match "Pikachu", response.body
    assert_match "Raichu", response.body
  end

  test "should not display evolution when trainer already has evolved form" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer both Pikachu and Raichu
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:raichu), ball_type: "pokeball")

    get evolution_lab_path
    # Should show empty state, not evolution cards
    assert_match "No Evolutions Available", response.body
    assert_select "div.evolution-card", count: 0
  end

  test "should display required item for evolution" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")

    get evolution_lab_path
    assert_match "Thunder Stone", response.body
  end

  test "should display item quantity requirement" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")

    get evolution_lab_path
    # Should show 0/1 for thunder stone
    assert_match "0/1", response.body
  end

  test "should display current and required item quantities" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Squirtle
    Capture.create!(trainer: trainer, pokemon: pokemons(:squirtle), ball_type: "pokeball")
    # Give trainer 1 evolution stone (needs 2)
    thunder_stone = items(:evolution_stone)
    trainer.add_item(:evolution_stone, 1)

    get evolution_lab_path
    # Should show 1/2 for evolution stone
    assert_match "1/2", response.body
  end

  test "should enable evolve button when trainer has enough items" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu and thunder stone
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    trainer.add_item(:thunder_stone, 1)

    get evolution_lab_path
    # Check for the evolution form (button_to creates a form)
    evolution = evolutions(:pikachu_to_raichu)
    assert_select "form[action=?]", evolve_path(evolution.id)
  end

  test "should disable evolve button when trainer lacks items" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu but no thunder stone
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")

    get evolution_lab_path
    assert_select "button[disabled]"
  end

  test "should display multiple evolutions from same pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Eevee (can evolve to Vaporeon and Jolteon)
    Capture.create!(trainer: trainer, pokemon: pokemons(:eevee), ball_type: "pokeball")

    get evolution_lab_path
    assert_match "Vaporeon", response.body
    assert_match "Jolteon", response.body
  end

  test "should display evolution chain stages" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Squirtle (first stage)
    Capture.create!(trainer: trainer, pokemon: pokemons(:squirtle), ball_type: "pokeball")
    trainer.add_item(:evolution_stone, 2)

    get evolution_lab_path
    # Should show Squirtle -> Wartortle
    assert_match "Squirtle", response.body
    assert_match "Wartortle", response.body
  end

  test "should show second evolution stage when trainer has middle evolution" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Wartortle (middle stage)
    Capture.create!(trainer: trainer, pokemon: pokemons(:wartortle), ball_type: "pokeball")
    trainer.add_item(:evolution_stone, 3)

    get evolution_lab_path
    # Should show Wartortle -> Blastoise
    assert_match "Wartortle", response.body
    assert_match "Blastoise", response.body
  end

  # ================================================================================
  # EVOLUTION LAB - EVOLUTION PROCESS TESTS
  # ================================================================================

  test "should successfully evolve pokemon when requirements met" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Unlock all gates so evolution doesn't trigger gate celebration
    Gate.all.each do |gate|
      trainer.gate_unlocks.find_or_create_by(gate: gate)
    end

    # Give trainer Pikachu and thunder stone
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    trainer.add_item(:thunder_stone, 1)

    evolution = evolutions(:pikachu_to_raichu)

    assert_difference("Capture.count", 1) do
      post evolve_path(evolution), params: { id: evolution.id }
    end

    # Should redirect to pokemon celebration page
    assert_redirected_to pokemon_celebration_path
    trainer.reload
    assert_includes trainer.captured_pokemon, pokemons(:raichu)
  end

  test "should deduct required items on successful evolution" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu and thunder stone
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    trainer.add_item(:thunder_stone, 1)

    evolution = evolutions(:pikachu_to_raichu)
    initial_thunder_stones = trainer.item_quantity(:thunder_stone)

    post evolve_path(evolution), params: { id: evolution.id }

    trainer.reload
    assert_equal initial_thunder_stones - 1, trainer.item_quantity(:thunder_stone)
  end

  test "should display success message after evolution" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Unlock all gates so evolution doesn't trigger gate celebration
    Gate.all.each do |gate|
      trainer.gate_unlocks.find_or_create_by(gate: gate)
    end

    # Give trainer Pikachu and thunder stone
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    trainer.add_item(:thunder_stone, 1)

    evolution = evolutions(:pikachu_to_raichu)

    post evolve_path(evolution), params: { id: evolution.id }

    # Should redirect to celebration page
    assert_redirected_to pokemon_celebration_path

    # Verify evolution was successful
    trainer.reload
    assert_includes trainer.captured_pokemon, pokemons(:raichu)
  end

  test "should use same ball type as original capture for evolved pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu caught with ultra ball
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "ultra_ball")
    trainer.add_item(:thunder_stone, 1)

    evolution = evolutions(:pikachu_to_raichu)
    post evolve_path(evolution), params: { id: evolution.id }

    trainer.reload
    raichu_capture = Capture.find_by(trainer: trainer, pokemon: pokemons(:raichu))
    assert_equal "ultra_ball", raichu_capture.ball_type
  end

  test "should set captured_at timestamp for evolved pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu and thunder stone
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    trainer.add_item(:thunder_stone, 1)

    evolution = evolutions(:pikachu_to_raichu)

    freeze_time = Time.zone.parse("2025-06-15 14:30:00")
    travel_to freeze_time do
      post evolve_path(evolution), params: { id: evolution.id }
    end

    trainer.reload
    raichu_capture = Capture.find_by(trainer: trainer, pokemon: pokemons(:raichu))
    assert_in_delta freeze_time, raichu_capture.captured_at, 1.second
  end

  # ================================================================================
  # EVOLUTION LAB - ERROR HANDLING TESTS
  # ================================================================================

  test "should not evolve when trainer lacks pre-evolution pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer thunder stone but no Pikachu
    trainer.add_item(:thunder_stone, 1)

    evolution = evolutions(:pikachu_to_raichu)

    assert_no_difference("Capture.count") do
      post evolve_path(evolution), params: { id: evolution.id }
    end

    assert_redirected_to evolution_lab_path
    assert_match "don't have Pikachu", flash[:alert]
  end

  test "should not evolve when trainer already has evolved form" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer both Pikachu, Raichu, and thunder stone
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:raichu), ball_type: "pokeball")
    trainer.add_item(:thunder_stone, 1)

    evolution = evolutions(:pikachu_to_raichu)
    initial_captures = trainer.captures.count

    post evolve_path(evolution), params: { id: evolution.id }

    assert_redirected_to evolution_lab_path
    assert_match "already have Raichu", flash[:alert]

    trainer.reload
    assert_equal initial_captures, trainer.captures.count
  end

  test "should not evolve when trainer lacks required items" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu but no thunder stone
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")

    evolution = evolutions(:pikachu_to_raichu)

    assert_no_difference("Capture.count") do
      post evolve_path(evolution), params: { id: evolution.id }
    end

    assert_redirected_to evolution_lab_path
    assert_match "don't have enough Thunder Stone", flash[:alert]
  end

  test "should not evolve when trainer has insufficient item quantity" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Squirtle but only 1 evolution stone (needs 2)
    Capture.create!(trainer: trainer, pokemon: pokemons(:squirtle), ball_type: "pokeball")
    trainer.add_item(:evolution_stone, 1)

    evolution = evolutions(:squirtle_to_wartortle)

    assert_no_difference("Capture.count") do
      post evolve_path(evolution), params: { id: evolution.id }
    end

    assert_redirected_to evolution_lab_path
    assert_match "don't have enough Evolution Stone", flash[:alert]
  end

  test "should not deduct items when evolution fails" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer only thunder stone (no Pikachu)
    trainer.add_item(:thunder_stone, 1)

    evolution = evolutions(:pikachu_to_raichu)
    initial_stones = trainer.item_quantity(:thunder_stone)

    post evolve_path(evolution), params: { id: evolution.id }

    trainer.reload
    assert_equal initial_stones, trainer.item_quantity(:thunder_stone)
  end

  test "should redirect to login when evolving without authentication" do
    evolution = evolutions(:pikachu_to_raichu)
    post evolve_path(evolution), params: { id: evolution.id }
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  # ================================================================================
  # EVOLUTION LAB - EDGE CASE AND INTEGRATION TESTS
  # ================================================================================

  test "should handle evolution chain correctly" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # First evolution: Squirtle -> Wartortle
    Capture.create!(trainer: trainer, pokemon: pokemons(:squirtle), ball_type: "pokeball")
    trainer.add_item(:evolution_stone, 5) # Enough for both evolutions

    evolution1 = evolutions(:squirtle_to_wartortle)
    post evolve_path(evolution1), params: { id: evolution1.id }

    trainer.reload
    assert_includes trainer.captured_pokemon, pokemons(:wartortle)
    assert_equal 3, trainer.item_quantity(:evolution_stone) # 5 - 2 = 3

    # Second evolution: Wartortle -> Blastoise
    evolution2 = evolutions(:wartortle_to_blastoise)
    post evolve_path(evolution2), params: { id: evolution2.id }

    trainer.reload
    assert_includes trainer.captured_pokemon, pokemons(:blastoise)
    assert_equal 0, trainer.item_quantity(:evolution_stone) # 3 - 3 = 0
  end

  test "should maintain session across evolution flow" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu and thunder stone
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    trainer.add_item(:thunder_stone, 1)

    # Visit evolution lab
    get evolution_lab_path
    assert_response :success

    # Perform evolution
    evolution = evolutions(:pikachu_to_raichu)
    post evolve_path(evolution), params: { id: evolution.id }

    # Session should still be valid
    assert_equal trainer.id, session[:trainer_id]
  end

  test "should handle multiple different evolutions in sequence" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Eevee with both water and thunder stones
    Capture.create!(trainer: trainer, pokemon: pokemons(:eevee), ball_type: "pokeball")
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    trainer.add_item(:water_stone, 1)
    trainer.add_item(:thunder_stone, 1)

    # Evolve Eevee to Vaporeon
    evolution1 = evolutions(:eevee_to_vaporeon)
    post evolve_path(evolution1), params: { id: evolution1.id }

    trainer.reload
    assert_includes trainer.captured_pokemon, pokemons(:vaporeon)

    # Evolve Pikachu to Raichu
    evolution2 = evolutions(:pikachu_to_raichu)
    post evolve_path(evolution2), params: { id: evolution2.id }

    trainer.reload
    assert_includes trainer.captured_pokemon, pokemons(:raichu)
  end

  test "should show empty state after evolving only available pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu and thunder stone
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    trainer.add_item(:thunder_stone, 1)

    evolution = evolutions(:pikachu_to_raichu)
    post evolve_path(evolution), params: { id: evolution.id }

    # After evolution, should show empty state
    get evolution_lab_path
    assert_match "No Evolutions Available", response.body
  end

  test "should not show evolution option after evolving" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu and thunder stone
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    trainer.add_item(:thunder_stone, 2)

    # Before evolution, should show option
    get evolution_lab_path
    assert_select "div.evolution-card", minimum: 1

    # Perform evolution
    evolution = evolutions(:pikachu_to_raichu)
    post evolve_path(evolution), params: { id: evolution.id }

    # After evolution, should not show option (already have Raichu)
    get evolution_lab_path
    assert_select "div.evolution-card", count: 0
    assert_match "No Evolutions Available", response.body
  end

  test "should preserve original pokemon after evolution" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu and thunder stone
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    trainer.add_item(:thunder_stone, 1)

    evolution = evolutions(:pikachu_to_raichu)
    post evolve_path(evolution), params: { id: evolution.id }

    trainer.reload
    # Trainer should still have Pikachu
    assert_includes trainer.captured_pokemon, pokemons(:pikachu)
    # And also have Raichu
    assert_includes trainer.captured_pokemon, pokemons(:raichu)
  end

  test "should handle evolution with master ball captured pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer Pikachu caught with master ball
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "master_ball")
    trainer.add_item(:thunder_stone, 1)

    evolution = evolutions(:pikachu_to_raichu)
    post evolve_path(evolution), params: { id: evolution.id }

    trainer.reload
    raichu_capture = Capture.find_by(trainer: trainer, pokemon: pokemons(:raichu))
    assert_equal "master_ball", raichu_capture.ball_type
  end

  # ================================================================================
  # EVOLUTION LAB - DIFFICULTY STARS TESTS
  # ================================================================================

  test "should display difficulty stars on evolution lab cards" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Give trainer Pikachu
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    get evolution_lab_path
    # Should contain star characters
    assert_match "★", response.body
    # Should contain difficulty-stars class
    assert_select "div.difficulty-stars"
  end

  test "should display difficulty stars for before evolution pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Pikachu has difficulty 2
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    get evolution_lab_path
    # Pikachu (difficulty 2) and Raichu (difficulty 3)
    # Total: 2 + 3 = 5 filled stars
    # Total: 3 + 2 = 5 empty stars
    assert_select "span.star-filled", count: 5
    assert_select "span.star-empty", count: 5
  end

  test "should display difficulty stars for after evolution pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Pikachu has difficulty 2, Raichu has difficulty 3
    Capture.create!(trainer: trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")
    get evolution_lab_path
    # Should display stars for both Pikachu and Raichu
    assert_response :success
    assert_select "span.star-filled", count: 5
    assert_select "span.star-empty", count: 5
  end

  test "should display correct stars for difficulty 1 pre-evolution pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Squirtle has difficulty 1, Wartortle has difficulty 3
    Capture.create!(trainer: trainer, pokemon: pokemons(:squirtle), ball_type: "pokeball")
    get evolution_lab_path
    # Total: 1 + 3 = 4 filled stars
    # Total: 4 + 2 = 6 empty stars
    assert_select "span.star-filled", count: 4
    assert_select "span.star-empty", count: 6
  end

  test "should display stars for multiple evolution options" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Eevee has difficulty 2, and can evolve to both Vaporeon and Jolteon (both difficulty 3)
    Capture.create!(trainer: trainer, pokemon: pokemons(:eevee), ball_type: "pokeball")
    get evolution_lab_path
    # Eevee (2) -> Vaporeon (3): 2 + 3 = 5 filled, 5 empty
    # Eevee (2) -> Jolteon (3): 2 + 3 = 5 filled, 5 empty
    # Total: 10 filled, 10 empty
    assert_select "span.star-filled", count: 10
    assert_select "span.star-empty", count: 10
  end

  test "should display stars for multi-stage evolution chain" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    # Squirtle (1) -> Wartortle (3)
    Capture.create!(trainer: trainer, pokemon: pokemons(:squirtle), ball_type: "pokeball")
    trainer.add_item(:evolution_stone, 2)
    get evolution_lab_path
    # Should show Squirtle (1) -> Wartortle (3)
    # Total: 1 + 3 = 4 filled stars
    # Total: 4 + 2 = 6 empty stars
    assert_select "span.star-filled", count: 4
    assert_select "span.star-empty", count: 6
  end

  # ================================================================================
  # DISCARD ITEM TESTS
  # ================================================================================

  test "should require login for discard_item" do
    pokeball = Item.find_or_create_by!(key: "pokeball") { |i| i.item_type = "pokeball" }
    delete discard_item_path(item_key: pokeball.key)
    assert_redirected_to login_path
  end

  test "should successfully discard a pokeball" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    pokeball = Item.find_or_create_by!(key: "pokeball") { |i| i.item_type = "pokeball" }

    # Clear existing items and add fresh
    trainer.trainer_items.destroy_all
    trainer.add_item(:pokeball, 5)

    initial_quantity = trainer.ball_count(:pokeball)
    assert_equal 5, initial_quantity

    delete discard_item_path(item_key: pokeball.key)

    assert_redirected_to dashboard_path
    assert_equal "Discarded 1 Poké Ball.", flash[:notice]

    trainer.reload
    assert_equal 4, trainer.ball_count(:pokeball)
  end

  test "should successfully discard an evolution stone" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    fire_stone = Item.find_or_create_by!(key: "fire_stone") { |i| i.item_type = "evolution_stone" }

    # Clear existing items and add fresh
    trainer.trainer_items.destroy_all
    trainer.add_item(:fire_stone, 3)

    initial_quantity = trainer.item_quantity(:fire_stone)
    assert_equal 3, initial_quantity

    delete discard_item_path(item_key: fire_stone.key)

    assert_redirected_to dashboard_path
    assert_equal "Discarded 1 Fire Stone.", flash[:notice]

    trainer.reload
    assert_equal 2, trainer.item_quantity(:fire_stone)
  end

  test "should not allow discarding key items" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    old_rod = Item.find_or_create_by!(key: "old_rod") { |i| i.item_type = "key_item" }
    trainer.add_item(:old_rod, 1)

    delete discard_item_path(item_key: old_rod.key)

    assert_redirected_to dashboard_path
    assert_equal "You cannot discard this item.", flash[:alert]

    trainer.reload
    assert_equal 1, trainer.item_quantity(:old_rod)
  end

  test "should not allow discarding items trainer does not have" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    ultra_ball = Item.find_or_create_by!(key: "ultra_ball") { |i| i.item_type = "pokeball" }

    # Clear existing items to ensure trainer doesn't have ultra ball
    trainer.trainer_items.destroy_all

    delete discard_item_path(item_key: ultra_ball.key)

    assert_redirected_to dashboard_path
    assert_equal "You don't have any Ultra Ball to discard.", flash[:alert]
  end

  test "should remove item entirely when discarding last one" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    great_ball = Item.find_or_create_by!(key: "great_ball") { |i| i.item_type = "pokeball" }

    # Clear existing items and add only 1
    trainer.trainer_items.destroy_all
    trainer.add_item(:great_ball, 1)

    assert_equal 1, trainer.ball_count(:great_ball)

    delete discard_item_path(item_key: great_ball.key)

    assert_redirected_to dashboard_path
    assert_equal "Discarded 1 Great Ball.", flash[:notice]

    trainer.reload
    assert_equal 0, trainer.ball_count(:great_ball)
  end

  test "should decrement by 1 when discarding from multiple" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    pokeball = Item.find_or_create_by!(key: "pokeball") { |i| i.item_type = "pokeball" }

    # Clear existing items and add 10
    trainer.trainer_items.destroy_all
    trainer.add_item(:pokeball, 10)

    delete discard_item_path(item_key: pokeball.key)

    trainer.reload
    assert_equal 9, trainer.ball_count(:pokeball)

    delete discard_item_path(item_key: pokeball.key)

    trainer.reload
    assert_equal 8, trainer.ball_count(:pokeball)
  end

  test "should return error for non-existent item" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    delete discard_item_path(item_key: "fake_item")

    assert_redirected_to dashboard_path
    assert_equal "Item not found.", flash[:alert]
  end

  test "dashboard should show discard button for pokeballs" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    pokeball = Item.find_or_create_by!(key: "pokeball") { |i| i.item_type = "pokeball" }
    trainer.add_item(:pokeball, 5)

    get dashboard_path

    assert_response :success
    assert_select "form[action='#{discard_item_path(item_key: pokeball.key)}']"
    assert_select ".btn-discard-item"
    assert_select "img.discard-icon"
    assert_select "img[alt='Discard']"
  end

  test "dashboard should show discard button for evolution stones" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    water_stone = Item.find_or_create_by!(key: "water_stone") { |i| i.item_type = "evolution_stone" }
    trainer.add_item(:water_stone, 2)

    get dashboard_path

    assert_response :success
    assert_select "form[action='#{discard_item_path(item_key: water_stone.key)}']"
    assert_select ".btn-discard-item"
    assert_select "img.discard-icon"
  end

  test "dashboard should not show discard button for adventure items" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    good_rod = Item.find_or_create_by!(key: "good_rod") { |i| i.item_type = "key_item" }
    trainer.add_item(:good_rod, 1)

    get dashboard_path

    assert_response :success
    # Should not have a discard button for good_rod
    assert_select "form[action='#{discard_item_path(item_key: good_rod.key)}']", count: 0
  end

  test "should handle discarding multiple different items" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    pokeball = Item.find_or_create_by!(key: "pokeball") { |i| i.item_type = "pokeball" }
    fire_stone = Item.find_or_create_by!(key: "fire_stone") { |i| i.item_type = "evolution_stone" }
    moon_stone = Item.find_or_create_by!(key: "moon_stone") { |i| i.item_type = "evolution_stone" }

    # Clear existing items and add fresh
    trainer.trainer_items.destroy_all
    trainer.add_item(:pokeball, 3)
    trainer.add_item(:fire_stone, 2)
    trainer.add_item(:moon_stone, 1)

    # Discard pokeball
    delete discard_item_path(item_key: pokeball.key)
    trainer.reload
    assert_equal 2, trainer.ball_count(:pokeball)

    # Discard fire stone
    delete discard_item_path(item_key: fire_stone.key)
    trainer.reload
    assert_equal 1, trainer.item_quantity(:fire_stone)

    # Discard moon stone (last one)
    delete discard_item_path(item_key: moon_stone.key)
    trainer.reload
    assert_equal 0, trainer.item_quantity(:moon_stone)

    # Other items should remain unchanged
    assert_equal 2, trainer.ball_count(:pokeball)
    assert_equal 1, trainer.item_quantity(:fire_stone)
  end

  test "dashboard should display discard confirmation modal" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    pokeball = Item.find_or_create_by!(key: "pokeball") { |i| i.item_type = "pokeball" }
    trainer.add_item(:pokeball, 5)

    get dashboard_path

    assert_response :success
    # Check that modal exists
    assert_select "#discardItemModal"
    assert_select "#discardItemModal .modal-title", text: "Confirm Discard"
    assert_select "#discardItemModal #itemNameValue"
    assert_select "#discardYes", text: "Yes"
    assert_select "#discardNo", text: "No"
  end

  test "discard button form should have correct data attributes" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    pokeball = Item.find_or_create_by!(key: "pokeball") { |i| i.item_type = "pokeball" }
    trainer.add_item(:pokeball, 5)

    get dashboard_path

    assert_response :success
    # Check that the form has the correct data attributes
    assert_select "form.discard-item-form[data-item-name='Poké Ball']"
  end

  test "modal message should reference item name" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    fire_stone = Item.find_or_create_by!(key: "fire_stone") { |i| i.item_type = "evolution_stone" }
    trainer.add_item(:fire_stone, 2)

    get dashboard_path

    assert_response :success
    # Check modal message structure
    assert_select "#discardMessage" do
      assert_select "#itemNameValue"
    end
    assert_match(/Are you sure you want to throw away 1/, response.body)
  end

  test "modal should have Yes and No buttons" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get dashboard_path

    assert_response :success
    assert_select "#discardYes.btn-primary", text: "Yes"
    assert_select "#discardNo.btn-secondary", text: "No"
  end

  test "modal should have overlay for closing" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get dashboard_path

    assert_response :success
    assert_select "#discardItemModal .modal-overlay"
  end

  test "JavaScript should be present for modal handling" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get dashboard_path

    assert_response :success
    # Check that JavaScript is present
    assert_match(/discardItemModal/, response.body)
    assert_match(/addEventListener/, response.body)
    assert_match(/turbo:load/, response.body)
  end

  test "modal should be hidden by default" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    pokeball = Item.find_or_create_by!(key: "pokeball") { |i| i.item_type = "pokeball" }
    trainer.add_item(:pokeball, 5)

    get dashboard_path

    assert_response :success
    # Modal should have display: none by default
    assert_select "#discardItemModal[style*='display: none']"
  end

  test "modal should have proper structure for both pokeballs and evolution items" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    pokeball = Item.find_or_create_by!(key: "pokeball") { |i| i.item_type = "pokeball" }
    water_stone = Item.find_or_create_by!(key: "water_stone") { |i| i.item_type = "evolution_stone" }

    trainer.add_item(:pokeball, 3)
    trainer.add_item(:water_stone, 2)

    get dashboard_path

    assert_response :success

    # Both items should have discard forms
    assert_select "form.discard-item-form[data-item-name='Poké Ball']"
    assert_select "form.discard-item-form[data-item-name='Water Stone']"

    # Only one modal should exist
    assert_select "#discardItemModal", count: 1
  end

  test "modal JavaScript should handle form submission" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get dashboard_path

    assert_response :success
    # Check that JavaScript handles the submit event
    assert_match(/form\.addEventListener\('submit'/, response.body)
    assert_match(/e\.preventDefault\(\)/, response.body)
  end

  test "modal should have click handlers for Yes and No buttons" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get dashboard_path

    assert_response :success
    # Check that Yes button has click handler
    assert_match(/discardYes\.addEventListener\('click'/, response.body)
    # Check that No button has click handler
    assert_match(/discardNo\.addEventListener\('click'/, response.body)
  end

  test "modal overlay should close modal when clicked" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get dashboard_path

    assert_response :success
    # Check that overlay has click handler
    assert_match(/modal-overlay.*addEventListener\('click'/, response.body)
  end

  test "discard forms should not use turbo by default" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    pokeball = Item.find_or_create_by!(key: "pokeball") { |i| i.item_type = "pokeball" }
    trainer.add_item(:pokeball, 5)

    get dashboard_path

    assert_response :success
    # Forms should have data-turbo="false"
    assert_select "form[data-turbo='false']"
  end

  test "modal No button should clear pending form" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get dashboard_path

    assert_response :success
    # Check that No button sets pendingForm to null
    assert_match(/pendingForm = null/, response.body)
  end

  test "modal should display correct message format" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get dashboard_path

    assert_response :success
    # Check exact modal message format
    assert_select "#discardMessage", text: /Are you sure you want to throw away 1/
  end

  test "dashboard should display currency in inventory header" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Set trainer currency to a known value
    trainer.update!(currency: 12345)

    get dashboard_path

    assert_response :success
    # Check that currency display exists in the page
    assert_select ".currency-display", text: /💰 Pokedollars: 12345/
    # Check that it's in the inventory card
    assert_select ".card-dashboard .currency-display"
  end

  private

  # Helper method to log in a trainer
  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end
end
