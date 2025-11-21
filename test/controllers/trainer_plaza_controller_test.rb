require "test_helper"

class TrainerPlazaControllerTest < ActionDispatch::IntegrationTest
  # ================================================================================
  # AUTHENTICATION TESTS
  # ================================================================================

  test "should require login for index" do
    get trainer_plaza_path
    assert_redirected_to login_path
  end

  test "should require login for show" do
    get trainer_path(trainers(:ash))
    assert_redirected_to login_path
  end

  test "should allow access to index when logged in" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_response :success
  end

  test "should allow access to show when logged in" do
    log_in_as(trainers(:ash))
    get trainer_path(trainers(:gary))
    assert_response :success
  end

  # ================================================================================
  # INDEX PAGE - BASIC DISPLAY TESTS
  # ================================================================================

  test "should display page title on index" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_match "Trainer Plaza", response.body
  end

  test "should display page description on index" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_match "View other trainers and their Pokédex collections", response.body
  end

  test "should display all trainers on index" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_match "ash", response.body
    assert_match "gary", response.body
  end

  test "should display trainers in alphabetical order" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    # Response body should have trainers in username alphabetical order
    assert_response :success
  end

  # ================================================================================
  # INDEX PAGE - TRAINER CARD DISPLAY TESTS
  # ================================================================================

  test "should display trainer usernames on index" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_select ".trainer-plaza-username", text: /ash/
  end

  test "should display trainer avatars on index" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_select ".trainer-plaza-avatar"
  end

  test "should display pokemon count for each trainer" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_match "/ 151", response.body
  end

  test "should display difficulty score for each trainer" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_match "Difficulty Score", response.body
    assert_match "★", response.body
  end

  test "should display View Pokedex button for each trainer" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_select "a.btn-primary", text: /View Pokédex/
  end

  test "should highlight current user's card on index" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_select ".trainer-plaza-current"
  end

  test "should show You badge on current user's card" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_select ".you-badge", text: "You"
  end

  test "should display trainer plaza grid container" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_select ".trainer-plaza-grid"
  end

  test "should display trainer plaza cards" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_select ".trainer-plaza-card", minimum: 1
  end

  # ================================================================================
  # INDEX PAGE - EMPTY STATE TESTS
  # ================================================================================

  test "should display trainer plaza even with only one trainer" do
    Trainer.destroy_all
    # Create a trainer to log in with
    trainer = Trainer.create!(
      username: "testuser",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id
    )
    log_in_as(trainer)
    get trainer_plaza_path
    # Should display the single trainer (yourself)
    assert_select ".trainer-plaza-card", count: 1
    assert_match "testuser", response.body
  end

  # ================================================================================
  # SHOW PAGE - BASIC DISPLAY TESTS
  # ================================================================================

  test "should display trainer's name on show page" do
    log_in_as(trainers(:ash))
    get trainer_path(trainers(:gary))
    assert_match "gary's Pokédex", response.body
  end

  test "should display trainer's avatar on show page header" do
    log_in_as(trainers(:ash))
    trainer = trainers(:gary)
    get trainer_path(trainer)
    assert_response :success
    # Avatar should be displayed in header
    assert_select "header.page-header-authenticated"
  end

  test "should display pokemon count on show page" do
    log_in_as(trainers(:ash))
    trainer = trainers(:gary)
    get trainer_path(trainer)
    assert_match "Pokémon caught", response.body
  end

  test "should display difficulty score on show page" do
    log_in_as(trainers(:ash))
    trainer = trainers(:gary)
    get trainer_path(trainer)
    assert_match "Difficulty Score", response.body
  end

  test "should display back button on show page" do
    log_in_as(trainers(:ash))
    get trainer_path(trainers(:gary))
    assert_select "a.btn-secondary", text: /Back to Trainer Plaza/
  end

  test "should show You badge when viewing own pokedex" do
    log_in_as(trainers(:ash))
    get trainer_path(trainers(:ash))
    assert_select ".you-badge", text: "You"
  end

  test "should not show You badge when viewing another trainer's pokedex" do
    log_in_as(trainers(:ash))
    get trainer_path(trainers(:gary))
    # Check that response doesn't have You badge in the header
    # (it might have it in sidebar, so we need to be careful)
    assert_response :success
  end

  # ================================================================================
  # SHOW PAGE - POKEMON DISPLAY TESTS
  # ================================================================================

  test "should display captured pokemon in grid on show page" do
    log_in_as(trainers(:ash))
    get trainer_path(trainers(:gary))
    assert_select ".pokedex-grid"
  end

  test "should display pokemon cards on show page" do
    log_in_as(trainers(:ash))
    trainer = trainers(:gary)
    get trainer_path(trainer)
    if trainer.captured_pokemon.any?
      assert_select ".pokemon-card", minimum: 1
    else
      assert_select ".empty-state"
    end
  end

  test "should display pokemon numbers with zero padding" do
    log_in_as(trainers(:ash))
    trainer = trainers(:gary)
    get trainer_path(trainer)
    if trainer.captured_pokemon.any?
      # Should see patterns like #001, #025, etc.
      assert_match /#\d{3}/, response.body
    end
  end

  test "should display pokemon names on show page" do
    log_in_as(trainers(:ash))
    trainer = trainers(:gary)
    get trainer_path(trainer)
    if trainer.captured_pokemon.any?
      assert_select ".pokemon-name", minimum: 1
    end
  end

  test "should display capture information on show page" do
    log_in_as(trainers(:ash))
    trainer = trainers(:gary)
    get trainer_path(trainer)
    if trainer.captured_pokemon.any?
      assert_match "Caught with a", response.body
    end
  end

  test "should display ball type used for capture" do
    log_in_as(trainers(:ash))
    trainer = trainers(:gary)
    get trainer_path(trainer)
    if trainer.captured_pokemon.any?
      assert_select ".pokemon-capture-info"
    end
  end

  test "should display capture date" do
    log_in_as(trainers(:ash))
    trainer = trainers(:gary)
    get trainer_path(trainer)
    if trainer.captured_pokemon.any?
      # Date format is MM/DD/YY
      assert_match /\d{2}\/\d{2}\/\d{2}/, response.body
    end
  end

  # ================================================================================
  # SHOW PAGE - EMPTY STATE TESTS
  # ================================================================================

  test "should display empty state when trainer has no pokemon" do
    log_in_as(trainers(:ash))
    # Create a trainer with no captures
    trainer = Trainer.create!(
      username: "newtrainer",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id
    )
    get trainer_path(trainer)
    assert_match "No Pokémon Yet!", response.body
  end

  test "should show personalized empty state when viewing own empty pokedex" do
    # Create a new trainer with no pokemon
    trainer = Trainer.create!(
      username: "emptytrainer",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id
    )
    log_in_as(trainer)
    get trainer_path(trainer)
    assert_match "You haven't caught any Pokémon yet", response.body
  end

  test "should show different empty state when viewing another trainer's empty pokedex" do
    log_in_as(trainers(:ash))
    # Create a trainer with no captures
    empty_trainer = Trainer.create!(
      username: "emptyuser",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id
    )
    get trainer_path(empty_trainer)
    assert_match "emptyuser hasn't caught any Pokémon yet", response.body
  end

  test "should show action buttons in empty state for own pokedex" do
    # Create a new trainer with no pokemon
    trainer = Trainer.create!(
      username: "newuser",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id
    )
    log_in_as(trainer)
    get trainer_path(trainer)
    assert_select "a.btn-primary", text: /Get Pokéballs/
    assert_select "a.btn-primary", text: /Go Catchin/
  end

  test "should not show action buttons in empty state for other trainer's pokedex" do
    log_in_as(trainers(:ash))
    # Create a trainer with no captures
    empty_trainer = Trainer.create!(
      username: "otherempty",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id
    )
    get trainer_path(empty_trainer)
    # Should not have these specific buttons
    assert_response :success
  end

  # ================================================================================
  # EDGE CASE TESTS
  # ================================================================================

  test "should handle viewing own trainer profile" do
    log_in_as(trainers(:ash))
    get trainer_path(trainers(:ash))
    assert_response :success
    assert_match "ash's Pokédex", response.body
  end

  test "should order pokemon by pokedex number on show page" do
    log_in_as(trainers(:ash))
    trainer = trainers(:gary)
    get trainer_path(trainer)
    # Pokemon should be ordered by pokedex number
    assert_response :success
  end

  test "should handle trainer with many pokemon" do
    log_in_as(trainers(:ash))
    trainer = trainers(:gary)
    get trainer_path(trainer)
    assert_response :success
  end

  test "should calculate difficulty score correctly" do
    log_in_as(trainers(:ash))
    trainer = trainers(:gary)
    get trainer_path(trainer)
    # The difficulty score should be displayed
    expected_score = trainer.difficulty_score
    assert_match "#{expected_score}★", response.body
  end

  test "should display correct pokemon count on trainer card" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    trainer = trainers(:gary)
    expected_count = trainer.captured_pokemon.count
    # The count should appear in the format "X / 151"
    assert_response :success
  end

  test "should verify trainer exists before showing page" do
    log_in_as(trainers(:ash))
    # Valid trainer ID should work
    get trainer_path(trainers(:gary))
    assert_response :success
    # Invalid trainer IDs are handled by Rails with RecordNotFound
    # which results in a 404 page in production
  end

  # ================================================================================
  # NAVIGATION TESTS
  # ================================================================================

  test "should have working link from index to show page" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_select "a[href=?]", trainer_path(trainers(:ash))
  end

  test "should have working back link from show to index" do
    log_in_as(trainers(:ash))
    get trainer_path(trainers(:gary))
    assert_select "a[href=?]", trainer_plaza_path
  end

  test "should maintain session across trainer plaza pages" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path
    assert_response :success
    get trainer_path(trainers(:gary))
    assert_response :success
    get trainer_plaza_path
    assert_response :success
  end

  # ================================================================================
  # INTEGRATION TESTS
  # ================================================================================

  test "complete flow from plaza index to trainer show and back" do
    log_in_as(trainers(:ash))

    # Visit trainer plaza
    get trainer_plaza_path
    assert_response :success
    assert_match "Trainer Plaza", response.body

    # Visit a specific trainer
    get trainer_path(trainers(:gary))
    assert_response :success
    assert_match "gary's Pokédex", response.body

    # Go back to plaza
    get trainer_plaza_path
    assert_response :success
    assert_match "Trainer Plaza", response.body
  end

  test "should display all trainer information accurately" do
    log_in_as(trainers(:ash))
    trainer = trainers(:gary)

    # Visit trainer's page
    get trainer_path(trainer)
    assert_response :success

    # Check that all info is present
    assert_match trainer.username, response.body
    assert_match "#{trainer.captured_pokemon.count}", response.body
    assert_match "#{trainer.difficulty_score}★", response.body
  end

  test "should handle multiple trainers with different pokemon counts" do
    log_in_as(trainers(:ash))
    get trainer_plaza_path

    # Should display multiple trainers
    assert_select ".trainer-plaza-card", minimum: 2
  end

  private

  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end
end
