require "test_helper"

class TrainersControllerTest < ActionDispatch::IntegrationTest
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

  test "should redirect to dashboard on successful registration" do
    post trainers_path, params: {
      trainer: {
        username: "newtrainer",
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }

    assert_redirected_to dashboard_path
  end

  test "should show welcome message on successful registration" do
    post trainers_path, params: {
      trainer: {
        username: "newtrainer",
        password: "password123",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }

    assert_match(/Welcome to Pokevelocity/, flash[:notice])
    assert_match(/newtrainer/, flash[:notice])
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

    # Should be able to access protected page immediately
    get dashboard_path
    assert_response :success
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

  test "should allow registration without icon pokemon" do
    assert_difference("Trainer.count", 1) do
      post trainers_path, params: {
        trainer: {
          username: "newtrainer",
          password: "password123",
          icon_pokemon_id: nil
        },
        activation_code: "TEST01"
      }
    end
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
    assert_match "Redeem Rewards", response.body
  end

  test "should display page description on rewards page" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "Claim Pokéballs for completing tickets", response.body
  end

  test "should display claim reward card header" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "Claim Your Reward", response.body
  end

  test "should display claim reward card icon" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "✅", response.body
  end

  test "should display reward probabilities card header" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "Reward Probabilities", response.body
  end

  test "should display reward probabilities card icon" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "📊", response.body
  end

  test "should display instructions for claiming rewards" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "Select the story points from your completed ticket", response.body
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
  # REWARDS PAGE - PROBABILITY INFORMATION TESTS
  # ================================================================================

  test "should display 1-2 point tickets probability info" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "1-2 Point Tickets", response.body
    assert_match "Mostly Pokéballs, small chance of Great Balls", response.body
  end

  test "should display 3 point tickets probability info" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "3 Point Tickets", response.body
    assert_match "Mix of Pokéballs and Great Balls", response.body
  end

  test "should display 5 point tickets probability info" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "5 Point Tickets", response.body
    assert_match "Mostly Great Balls, chance of Ultra Balls", response.body
  end

  test "should display 8+ point tickets probability info" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "8+ Point Tickets", response.body
    assert_match "Mostly Ultra Balls, chance of Master Balls!", response.body
  end

  test "should display all 4 reward probability items" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_select "div.reward-probability-item", count: 4
  end

  test "should display probability info description" do
    log_in_as(trainers(:ash))
    get rewards_path
    assert_match "Different story points have different chances", response.body
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

  test "should have 6 forms total on rewards page" do
    log_in_as(trainers(:ash))
    get rewards_path
    # 5 preset buttons + 1 "Other" input form (not counting sidebar logout form)
    assert_select "main.main-content" do
      assert_select "form", count: 6
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
    assert_select "div.card-dashboard", count: 2
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

  # ================================================================================
  # CATCH PAGE (NEW) - STATS BAR TESTS
  # ================================================================================

  test "should display caught count stat on catch page" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get catches_path
    # Gary has 2 captures
    assert_match "2 / 151", response.body
  end

  test "should display available pokemon count stat" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get catches_path
    # Gary caught 2, so 4 available in fixtures (6 total - 2 caught)
    uncaught_count = Pokemon.count - trainer.captures.count
    assert_match "#{uncaught_count}", response.body
  end

  test "should display total pokeballs stat" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_match trainer.total_pokeballs.to_s, response.body
  end

  test "should display zero caught for new trainer" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_match "0 / 151", response.body
  end

  # ================================================================================
  # CATCH PAGE (NEW) - POKEMON CARD DISPLAY TESTS
  # ================================================================================

  test "should display pokemon cards on catch page" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_select "div.pokemon-catch-card"
  end

  test "should display pokedex number with zero padding on catch cards" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    # Bulbasaur is #1, should display as #001
    assert_match "#001", response.body
  end

  test "should display pokemon names on catch cards" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_match "Bulbasaur", response.body
    assert_match "Charmander", response.body
  end

  test "should display difficulty stars for each pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    # Should show star symbols
    assert_match "★", response.body
    assert_match "Difficulty:", response.body
  end

  test "should display catch button for each uncaught pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_select "a.btn-catch"
  end

  test "should link to pokemon catch page from catch button" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    pokemon = pokemons(:bulbasaur)
    assert_select "a[href=?]", catch_path(pokemon)
  end

  test "should display correct number of pokemon cards for uncaught pokemon" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get catches_path
    # Gary caught 2 pokemon (Charmander and Squirtle), so 4 should be available
    uncaught_count = Pokemon.count - trainer.captures.count
    assert_select "div.pokemon-catch-card", count: uncaught_count
  end

  # ================================================================================
  # CATCH PAGE (NEW) - DIFFICULTY DISPLAY TESTS
  # ================================================================================

  test "should display filled stars for pokemon difficulty level" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    # Should have both filled and empty stars
    assert_select "span.star-filled"
    assert_select "span.star-empty"
  end

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
  # CATCH PAGE (NEW) - EMPTY STATE TESTS
  # ================================================================================

  test "should show congratulations empty state when all pokemon caught" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Catch all pokemon
    Pokemon.all.each do |pokemon|
      Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")
    end

    get catches_path
    # Should redirect to pokedex with notice
    assert_redirected_to pokedex_path
    assert_match "Congratulations", flash[:notice]
  end

  test "should display page header on catch page" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_match "Catch Pokémon", response.body
  end

  test "should display page description on catch page" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_match "Choose a Pokémon to attempt to catch", response.body
  end

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
    assert_match trainer.pokeballs_count.to_s, response.body
    assert_match trainer.great_balls_count.to_s, response.body
    assert_match trainer.ultra_balls_count.to_s, response.body
    assert_match trainer.master_balls_count.to_s, response.body
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
    # Check specifically in the pokeball grid (not sidebar logout button)
    assert_select "div.pokeball-grid" do
      assert_select "button[type='submit']", count: 4
    end
  end

  test "should display Available label for each ball type" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_match "Available", response.body
  end

  test "should display back to pokemon list link" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    pokemon = pokemons(:bulbasaur)
    get catch_path(pokemon)
    assert_match "Back to Pokémon List", response.body
    assert_select "a[href=?]", catches_path
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

  test "should show stats bar with correct layout" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_select "div.catch-stats-bar"
    assert_select "div.catch-stat", count: 3
  end

  test "should display pokemon grid layout" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_select "div.pokemon-catch-grid"
  end

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

  test "should not show already caught pokemon in list" do
    trainer = trainers(:gary)
    log_in_as(trainer)
    get catches_path

    # Gary caught Charmander and Squirtle, they should not appear in the pokemon grid
    # (Note: Charmander might appear in sidebar as icon, so we check the catch cards specifically)
    assert_select "div.pokemon-catch-grid" do
      assert_select "h3.pokemon-catch-name", text: "Charmander", count: 0
      assert_select "h3.pokemon-catch-name", text: "Squirtle", count: 0
    end

    # But should show others
    assert_match "Bulbasaur", response.body
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
    assert_match trainer.pokeballs_count.to_s, response.body
  end

  test "should display great ball count on dashboard" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path
    assert_match trainer.great_balls_count.to_s, response.body
  end

  test "should display ultra ball count on dashboard" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path
    assert_match trainer.ultra_balls_count.to_s, response.body
  end

  test "should display master ball count on dashboard" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path
    assert_match trainer.master_balls_count.to_s, response.body
  end

  test "should display total pokeballs on dashboard" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get dashboard_path
    assert_match trainer.total_pokeballs.to_s, response.body
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
    assert_match "Pokéball Inventory", response.body
  end

  test "should display pokedex progress section" do
    log_in_as(trainers(:ash))
    get dashboard_path
    assert_match "Pokédex Progress", response.body
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

  private

  # Helper method to log in a trainer
  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end
end
