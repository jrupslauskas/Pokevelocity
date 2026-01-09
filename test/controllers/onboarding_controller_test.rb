require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  # ================================================================================
  # AUTHENTICATION TESTS
  # ================================================================================

  test "should require login for welcome" do
    get onboarding_welcome_path
    assert_redirected_to login_path
  end

  test "should require login for choose_starter" do
    get onboarding_choose_starter_path
    assert_redirected_to login_path
  end

  test "should require login for create_starter" do
    post onboarding_create_starter_path, params: { pokemon_id: 1 }
    assert_redirected_to login_path
  end

  # ================================================================================
  # WELCOME PAGE TESTS
  # ================================================================================

  test "should show welcome page for trainer without onboarding" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    get onboarding_welcome_path
    assert_response :success
  end

  test "should redirect to dashboard if onboarding already completed on welcome" do
    trainer = create_trainer_with_onboarding
    log_in_as(trainer)

    get onboarding_welcome_path
    assert_redirected_to dashboard_path
  end

  # ================================================================================
  # CHOOSE STARTER PAGE TESTS
  # ================================================================================

  test "should show choose starter page for trainer without onboarding" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    get onboarding_choose_starter_path
    assert_response :success
  end

  test "should display all three starters on choose starter page" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    get onboarding_choose_starter_path
    assert_response :success

    # Should display all three starters
    assert_select ".starter-card", count: 3
  end

  test "should display Bulbasaur as starter option" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    get onboarding_choose_starter_path
    assert_match /Bulbasaur/i, response.body
  end

  test "should display Charmander as starter option" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    get onboarding_choose_starter_path
    assert_match /Charmander/i, response.body
  end

  test "should display Squirtle as starter option" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    get onboarding_choose_starter_path
    assert_match /Squirtle/i, response.body
  end

  test "should redirect to dashboard if onboarding already completed on choose starter" do
    trainer = create_trainer_with_onboarding
    log_in_as(trainer)

    get onboarding_choose_starter_path
    assert_redirected_to dashboard_path
  end

  # ================================================================================
  # CREATE STARTER TESTS - VALID SELECTIONS
  # ================================================================================

  test "should allow selecting Bulbasaur as starter" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    bulbasaur = Pokemon.find_by(pokedex_number: 1)
    assert_difference "trainer.captures.count", 1 do
      post onboarding_create_starter_path, params: { pokemon_id: bulbasaur.id }
    end

    assert_redirected_to onboarding_sendoff_path
    trainer.reload
    assert_equal bulbasaur, trainer.captured_pokemon.first
  end

  test "should allow selecting Charmander as starter" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    charmander = Pokemon.find_by(pokedex_number: 4)
    assert_difference "trainer.captures.count", 1 do
      post onboarding_create_starter_path, params: { pokemon_id: charmander.id }
    end

    assert_redirected_to onboarding_sendoff_path
    trainer.reload
    assert_equal charmander, trainer.captured_pokemon.first
  end

  test "should allow selecting Squirtle as starter" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    squirtle = Pokemon.find_by(pokedex_number: 7)
    assert_difference "trainer.captures.count", 1 do
      post onboarding_create_starter_path, params: { pokemon_id: squirtle.id }
    end

    assert_redirected_to onboarding_sendoff_path
    trainer.reload
    assert_equal squirtle, trainer.captured_pokemon.first
  end

  # ================================================================================
  # CREATE STARTER TESTS - INVALID SELECTIONS
  # ================================================================================

  test "should reject non-starter Pokemon" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    pikachu = Pokemon.find_by(pokedex_number: 25)
    assert_no_difference "trainer.captures.count" do
      post onboarding_create_starter_path, params: { pokemon_id: pikachu.id }
    end

    assert_redirected_to onboarding_choose_starter_path
    assert_match /valid starter/i, flash[:alert]

    trainer.reload
    assert_not trainer.onboarding_completed
  end

  test "should reject evolved form of starter" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    # Try to select Blastoise (evolved form of Squirtle)
    blastoise = Pokemon.find_by(pokedex_number: 9)
    assert_no_difference "trainer.captures.count" do
      post onboarding_create_starter_path, params: { pokemon_id: blastoise.id }
    end

    assert_redirected_to onboarding_choose_starter_path
    assert_match /valid starter/i, flash[:alert]
  end

  # ================================================================================
  # ONBOARDING COMPLETION TESTS
  # ================================================================================

  test "should not mark onboarding as completed after selecting starter" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    assert_not trainer.onboarding_completed

    bulbasaur = Pokemon.find_by(pokedex_number: 1)
    post onboarding_create_starter_path, params: { pokemon_id: bulbasaur.id }

    trainer.reload
    assert_not trainer.onboarding_completed
  end

  test "should mark onboarding as completed after completing onboarding" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    bulbasaur = Pokemon.find_by(pokedex_number: 1)
    post onboarding_create_starter_path, params: { pokemon_id: bulbasaur.id }
    post onboarding_complete_path

    trainer.reload
    assert trainer.onboarding_completed
  end

  test "should give trainer 1 pokeball and 100 currency after completing onboarding" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    assert_equal 0, trainer.item_quantity(:pokeball)
    assert_equal 0, trainer.currency

    bulbasaur = Pokemon.find_by(pokedex_number: 1)
    post onboarding_create_starter_path, params: { pokemon_id: bulbasaur.id }
    post onboarding_complete_path

    trainer.reload
    assert_equal 1, trainer.item_quantity(:pokeball)
    assert_equal 100, trainer.currency
  end

  test "should not give other ball types with starter" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    bulbasaur = Pokemon.find_by(pokedex_number: 1)
    post onboarding_create_starter_path, params: { pokemon_id: bulbasaur.id }
    post onboarding_complete_path

    trainer.reload
    assert_equal 1, trainer.item_quantity(:pokeball)
    assert_equal 0, trainer.item_quantity(:great_ball)
    assert_equal 0, trainer.item_quantity(:ultra_ball)
    assert_equal 0, trainer.item_quantity(:master_ball)
  end

  test "should show welcome message after completing onboarding" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    bulbasaur = Pokemon.find_by(pokedex_number: 1)
    post onboarding_create_starter_path, params: { pokemon_id: bulbasaur.id }
    post onboarding_complete_path

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_match /Welcome to your journey/i, flash[:notice]
  end

  test "starter should be marked with pokeball as ball_type" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    charmander = Pokemon.find_by(pokedex_number: 4)
    post onboarding_create_starter_path, params: { pokemon_id: charmander.id }

    trainer.reload
    capture = trainer.captures.first
    assert_equal 'pokeball', capture.ball_type
  end

  test "starter should not be marked as evolved" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    squirtle = Pokemon.find_by(pokedex_number: 7)
    post onboarding_create_starter_path, params: { pokemon_id: squirtle.id }

    trainer.reload
    capture = trainer.captures.first
    assert_not capture.evolved
  end

  # ================================================================================
  # ALREADY COMPLETED TESTS
  # ================================================================================

  test "completed trainer cannot create another starter" do
    trainer = create_trainer_with_onboarding
    log_in_as(trainer)

    # Try to get another starter
    bulbasaur = Pokemon.find_by(pokedex_number: 1)
    assert_no_difference "trainer.captures.count" do
      post onboarding_create_starter_path, params: { pokemon_id: bulbasaur.id }
    end

    # Should be redirected to dashboard, not allowed to get starter
    assert_redirected_to dashboard_path
  end

  # ================================================================================
  # SENDOFF PAGE TESTS
  # ================================================================================

  test "should display sendoff page after selecting starter" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    bulbasaur = Pokemon.find_by(pokedex_number: 1)
    post onboarding_create_starter_path, params: { pokemon_id: bulbasaur.id }

    get onboarding_sendoff_path
    assert_response :success
    assert_match /Good Luck,/i, response.body
    assert_match /Bulbasaur/i, response.body
  end

  test "should require starter selection before showing sendoff" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    get onboarding_sendoff_path
    assert_redirected_to onboarding_choose_starter_path
    assert_match /choose your starter first/i, flash[:alert]
  end

  # ================================================================================
  # INTEGRATION TESTS
  # ================================================================================

  test "complete onboarding flow from welcome to dashboard" do
    trainer = create_trainer_without_onboarding
    log_in_as(trainer)

    # Step 1: Visit welcome page
    get onboarding_welcome_path
    assert_response :success
    assert_match /Welcome to Pok[ée]velocity/i, response.body

    # Step 2: Visit choose starter page
    get onboarding_choose_starter_path
    assert_response :success
    assert_select ".starter-card", count: 3

    # Step 3: Select Charmander
    charmander = Pokemon.find_by(pokedex_number: 4)
    post onboarding_create_starter_path, params: { pokemon_id: charmander.id }
    assert_redirected_to onboarding_sendoff_path

    # Step 4: Visit sendoff page
    get onboarding_sendoff_path
    assert_response :success
    assert_match /Charmander/i, response.body

    # Step 5: Complete onboarding
    post onboarding_complete_path
    assert_redirected_to dashboard_path

    # Verify completion
    trainer.reload
    assert trainer.onboarding_completed
    assert_equal 1, trainer.captured_pokemon.count
    assert_equal charmander, trainer.captured_pokemon.first
    assert_equal 1, trainer.item_quantity(:pokeball)
    assert_equal 100, trainer.currency
  end

  test "all three starters should work in the complete flow" do
    [1, 4, 7].each_with_index do |pokedex_number, index|
      trainer = Trainer.create!(
        username: "starter_test_#{index}_#{rand(10000)}",
        password: "password",
        icon_pokemon_id: pokemons(:pikachu).id,
        onboarding_completed: false
      )

      log_in_as(trainer)

      get onboarding_welcome_path
      assert_response :success

      get onboarding_choose_starter_path
      assert_response :success

      starter = Pokemon.find_by(pokedex_number: pokedex_number)
      post onboarding_create_starter_path, params: { pokemon_id: starter.id }
      assert_redirected_to onboarding_sendoff_path

      post onboarding_complete_path
      assert_redirected_to dashboard_path

      trainer.reload
      assert trainer.onboarding_completed
      assert_equal starter, trainer.captured_pokemon.first
      assert_equal 1, trainer.item_quantity(:pokeball)
      assert_equal 100, trainer.currency
    end
  end

  private

  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end

  def create_trainer_without_onboarding
    Trainer.create!(
      username: "newtrainer_#{rand(10000)}",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id,
      onboarding_completed: false
    )
  end

  def create_trainer_with_onboarding
    Trainer.create!(
      username: "completed_#{rand(10000)}",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id,
      onboarding_completed: true
    )
  end
end
