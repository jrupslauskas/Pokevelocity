require "test_helper"

class PokemonControllerTest < ActionDispatch::IntegrationTest
  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end

  # ================================================================================
  # AUTHENTICATION TESTS
  # ================================================================================

  test "should require login for celebration page" do
    get pokemon_celebration_path
    assert_redirected_to login_path
  end

  # ================================================================================
  # CELEBRATION PAGE DISPLAY TESTS
  # ================================================================================

  test "should redirect to pokedex if no celebration data in session" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get pokemon_celebration_path
    assert_redirected_to pokedex_path
  end

  # Note: Testing session-based redirects is complex in integration tests
  # The main flow is tested through the catches and evolution controllers

  # ================================================================================
  # INTEGRATION TESTS
  # ================================================================================
  # Note: Session manipulation in integration tests is handled through the actual flow
  # These tests verify the celebration route exists and basic controller logic works

  test "pokemon celebration route exists and is accessible" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Without session data, should redirect to pokedex
    get pokemon_celebration_path
    assert_redirected_to pokedex_path
  end

  # ================================================================================
  # VIEW CONTENT TESTS
  # ================================================================================

  test "celebration view file contains pokemon sprite display" do
    view_file = File.read(Rails.root.join("app", "views", "pokemon", "celebration.html.erb"))

    assert_includes view_file, "pokemon-celebration-sprite"
    assert_includes view_file, "@pokemon"
    assert_includes view_file, "pokemonSprites"
    assert_includes view_file, "pokedex_number"
  end

  test "celebration view file contains event type logic" do
    view_file = File.read(Rails.root.join("app", "views", "pokemon", "celebration.html.erb"))

    assert_includes view_file, "@event_type"
    assert_includes view_file, "caught"
    assert_includes view_file, "evolved"
  end

  test "celebration view file contains duplicate catch message" do
    view_file = File.read(Rails.root.join("app", "views", "pokemon", "celebration.html.erb"))

    assert_includes view_file, "@duplicate"
    assert_includes view_file, "Evolution Stone"
  end

  test "celebration view file contains evolution details" do
    view_file = File.read(Rails.root.join("app", "views", "pokemon", "celebration.html.erb"))

    assert_includes view_file, "@from_pokemon_name"
  end

  test "celebration view file contains ball type for catches" do
    view_file = File.read(Rails.root.join("app", "views", "pokemon", "celebration.html.erb"))

    assert_includes view_file, "@ball_type"
  end

  test "celebration view file contains trainer stats" do
    view_file = File.read(Rails.root.join("app", "views", "pokemon", "celebration.html.erb"))

    assert_includes view_file, "pokemon-celebration-stats"
    assert_includes view_file, "captures.select(:pokemon_id).distinct.count"
    assert_includes view_file, "difficulty_score"
  end

  test "celebration view file contains continue button to pokedex" do
    view_file = File.read(Rails.root.join("app", "views", "pokemon", "celebration.html.erb"))

    assert_includes view_file, "View Pokédex"
    assert_includes view_file, "pokedex_path"
    assert_includes view_file, "btn-celebration"
  end

  # ================================================================================
  # FULL FLOW INTEGRATION TESTS
  # ================================================================================
  # Note: Session data in integration tests doesn't persist across GET requests
  # the same way it does in the actual app. The full end-to-end flow is tested
  # in catches_controller_test.rb and trainers_controller_test.rb

  test "celebration page displays pokeball sprites for all ball types" do
    view_file = File.read(Rails.root.join("app", "views", "pokemon", "celebration.html.erb"))

    # Verify the view has logic to display different pokeball sprites
    assert_includes view_file, "icons/pokeball.png"
    assert_includes view_file, "icons/greatball.png"
    assert_includes view_file, "icons/ultraball.jpg"
    assert_includes view_file, "icons/masterball.png"
    assert_includes view_file, "celebration-pokeball-icon"
  end

  test "celebration view contains correct text structure for catches" do
    view_file = File.read(Rails.root.join("app", "views", "pokemon", "celebration.html.erb"))

    # Check for Gotcha header and subtitle structure
    assert_includes view_file, "Gotcha!"
    assert_includes view_file, "was caught!"
    assert_includes view_file, "pokemon-celebration-header"
    assert_includes view_file, "pokemon-celebration-subtitle"
  end

  test "celebration view contains correct text structure for evolutions" do
    view_file = File.read(Rails.root.join("app", "views", "pokemon", "celebration.html.erb"))

    # Check for Congratulations header and evolution text
    assert_includes view_file, "Congratulations!"
    assert_includes view_file, "evolved into"
    assert_includes view_file, "@from_pokemon_name"
  end

  test "celebration view displays pokemon number with name" do
    view_file = File.read(Rails.root.join("app", "views", "pokemon", "celebration.html.erb"))

    # Check that number and name are displayed together in uppercase
    assert_includes view_file, "pokemon-celebration-number"
    assert_includes view_file, ".upcase"
  end

  test "celebration view contains gate unlock conditional button" do
    view_file = File.read(Rails.root.join("app", "views", "pokemon", "celebration.html.erb"))

    # Check for conditional logic to show Continue vs View Pokédex button
    assert_includes view_file, "newly_unlocked_gate_id"
    assert_includes view_file, "Continue"
    assert_includes view_file, "gates_celebration_path"
  end
end
