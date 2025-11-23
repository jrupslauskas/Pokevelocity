require "test_helper"

class CatchesControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create test gates
    @gate_0 = Gate.create!(
      gate_number: 0,
      name: "Starting Gate",
      required_difficulty_score: 0,
      sprite_type: "emoji",
      sprite_value: "🎓"
    )

    @gate_1 = Gate.create!(
      gate_number: 1,
      name: "Test Gym",
      required_difficulty_score: 5,
      sprite_type: "emoji",
      sprite_value: "🏆"
    )

    # Create test route with encounters (using data from fixtures for Pokemon)
    @test_route = Route.create!(
      name: "Test Route",
      description: "A test route for catching Pokemon",
      gate_requirement: 0,
      order: 1
    )

    @locked_route = Route.create!(
      name: "Locked Route",
      description: "A locked route requiring gate 1",
      gate_requirement: 1,
      order: 2
    )

    # Add some Pokemon to the test route
    RouteEncounter.create!(route: @test_route, pokemon: pokemons(:bulbasaur), spawn_rate: 50)
    RouteEncounter.create!(route: @test_route, pokemon: pokemons(:charmander), spawn_rate: 30)
    RouteEncounter.create!(route: @test_route, pokemon: pokemons(:squirtle), spawn_rate: 20)

    # Add Pokemon to locked route
    RouteEncounter.create!(route: @locked_route, pokemon: pokemons(:pikachu), spawn_rate: 100)
  end

  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end

  # ================================================================================
  # ROUTE DISPLAY TESTS (NEW CATCH PAGE)
  # ================================================================================

  test "should display routes on catch page" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_response :success
    assert_select "div.routes-grid"
    assert_select "div.route-card"
  end

  test "should display route names" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_match "Test Route", response.body
  end

  test "should display route descriptions" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_match @test_route.description, response.body
  end

  test "should display wild pokemon for each route" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_select "div.route-pokemon-list"
    assert_select "div.route-pokemon-item"
  end

  test "should display adventure button for routes with available pokemon" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_select "button.btn-adventure"
  end

  test "should show pokemon available count for each route" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_match "Pokémon available", response.body
  end

  test "should mark caught pokemon as caught on route display" do
    trainer = trainers(:ash)
    # Catch Bulbasaur
    Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")

    log_in_as(trainer)
    get catches_path
    # Should have caught class on pokemon item
    assert_select "div.route-pokemon-item.caught"
  end

  test "should disable adventure button when all route pokemon are caught" do
    trainer = trainers(:ash)

    # Catch all Pokemon on the test route
    @test_route.pokemon.each do |pokemon|
      Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")
    end

    log_in_as(trainer)
    get catches_path
    assert_select "button.btn-adventure-disabled"
    assert_match "All caught!", response.body
  end

  test "should display stats bar with caught count and pokeballs" do
    trainer = trainers(:ash)
    log_in_as(trainer)
    get catches_path
    assert_select "div.catch-stats-bar"
    assert_match "/ 151", response.body
    assert_match "Pokéballs", response.body
  end

  test "should redirect when no routes exist" do
    trainer = trainers(:ash)
    Route.destroy_all

    log_in_as(trainer)
    get catches_path
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_match "No routes available", response.body
  end

  # ================================================================================
  # ADVENTURE ACTION TESTS
  # ================================================================================

  test "should redirect to pokemon encounter on adventure" do
    trainer = trainers(:ash)

    log_in_as(trainer)
    post adventure_path(@test_route)

    assert_response :redirect
    # Should redirect to a catch page for a pokemon
    assert_match /\/catch\/\d+/, response.headers["Location"]
  end

  test "should encounter pokemon from correct route" do
    trainer = trainers(:ash)

    log_in_as(trainer)
    post adventure_path(@test_route)

    follow_redirect!
    # Should encounter one of the pokemon from the test route
    route_pokemon_names = @test_route.pokemon.pluck(:name)
    assert route_pokemon_names.any? { |name| response.body.include?(name) }
  end

  test "should not encounter already caught pokemon on adventure" do
    trainer = trainers(:ash)

    # Catch all but one pokemon on the route
    @test_route.pokemon[0..-2].each do |pokemon|
      Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")
    end

    last_pokemon = @test_route.pokemon.last

    log_in_as(trainer)
    # Adventure multiple times to verify we only encounter the uncaught one
    5.times do
      post adventure_path(@test_route)
      follow_redirect!
      assert_match last_pokemon.name, response.body
    end
  end

  test "should redirect with notice when all route pokemon are caught" do
    trainer = trainers(:ash)

    # Catch all pokemon on the route
    @test_route.pokemon.each do |pokemon|
      Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")
    end

    log_in_as(trainer)
    post adventure_path(@test_route)

    assert_redirected_to catches_path
    follow_redirect!
    assert_match /caught all|all.*caught/i, response.body
  end

  test "should require login for adventure" do
    post adventure_path(@test_route)
    assert_redirected_to login_path
  end

  # ================================================================================
  # POKEMON ENCOUNTER PAGE TESTS (EXISTING FUNCTIONALITY)
  # ================================================================================

  test "should show pokemon encounter page" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    log_in_as(trainer)
    get catch_path(pokemon)

    assert_response :success
    assert_match pokemon.name, response.body
  end

  test "should show catch probabilities on encounter page" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    log_in_as(trainer)
    get catch_path(pokemon)

    assert_match "Pokéball", response.body
    assert_match "Great Ball", response.body
  end

  test "should redirect if pokemon already caught" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)
    Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")

    log_in_as(trainer)
    get catch_path(pokemon)

    assert_redirected_to catches_path
    follow_redirect!
    assert_match "already caught", response.body
  end

  # ================================================================================
  # GATE SYSTEM TESTS
  # ================================================================================

  test "should display gates on catch page" do
    trainer = trainers(:ash)
    # Unlock gate 0 for the trainer
    GateUnlock.create!(trainer: trainer, gate: @gate_0, unlocked_at: Time.current)

    log_in_as(trainer)
    get catches_path

    assert_response :success
    assert_select "div.gate-card"
    assert_match @gate_0.name, response.body
  end

  test "should show unlocked status for unlocked gates" do
    trainer = trainers(:ash)
    GateUnlock.create!(trainer: trainer, gate: @gate_0, unlocked_at: Time.current)

    log_in_as(trainer)
    get catches_path

    assert_match "Unlocked", response.body
  end

  test "should show locked status for locked gates" do
    trainer = trainers(:ash)
    GateUnlock.create!(trainer: trainer, gate: @gate_0, unlocked_at: Time.current)

    log_in_as(trainer)
    get catches_path

    assert_match "Locked", response.body
  end

  test "should auto-unlock gates when trainer meets requirement" do
    trainer = trainers(:ash)

    # Initially no gates unlocked
    assert_equal 0, trainer.unlocked_gates.count

    log_in_as(trainer)
    get catches_path

    # Gate 0 should be auto-unlocked (requirement: 0)
    assert_equal 1, trainer.unlocked_gates.count
    assert trainer.has_unlocked_gate?(@gate_0)
  end

  test "should show notification when gates are unlocked" do
    trainer = trainers(:ash)

    log_in_as(trainer)
    get catches_path

    # Should show unlock notification for gate 0
    assert_match "unlocked", response.body.downcase
  end

  test "should only show routes up to next locked gate" do
    trainer = trainers(:ash)
    GateUnlock.create!(trainer: trainer, gate: @gate_0, unlocked_at: Time.current)

    log_in_as(trainer)
    get catches_path

    # Should show test route (gate 0)
    assert_match "Test Route", response.body

    # Should NOT show locked route (gate 1)
    assert_no_match "Locked Route", response.body
  end

  test "should display difficulty score in stats bar" do
    trainer = trainers(:ash)
    GateUnlock.create!(trainer: trainer, gate: @gate_0, unlocked_at: Time.current)

    log_in_as(trainer)
    get catches_path

    assert_match "Difficulty Score", response.body
  end

  test "should show gate progress bars" do
    trainer = trainers(:ash)
    GateUnlock.create!(trainer: trainer, gate: @gate_0, unlocked_at: Time.current)

    log_in_as(trainer)
    get catches_path

    assert_select "div.gate-progress-bar"
    assert_select "div.gate-progress-fill"
  end

  test "should show routes for newly unlocked gates" do
    trainer = trainers(:ash)

    log_in_as(trainer)
    get catches_path

    # Initially locked route should not be visible (trainer has difficulty score 0, gate 1 requires 5)
    assert_no_match "Locked Route", response.body

    # Give trainer enough Pokemon to meet gate 1 requirement (difficulty score >= 5)
    # Mewtwo has difficulty 5, which meets the requirement
    Capture.create!(trainer: trainer, pokemon: pokemons(:mewtwo), ball_type: "pokeball")

    # Refresh page
    get catches_path

    # Now locked route should be visible (trainer meets gate 1 requirement)
    assert_match "Locked Route", response.body
  end
end
