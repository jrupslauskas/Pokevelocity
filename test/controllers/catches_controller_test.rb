require "test_helper"

class CatchesControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create test route with encounters (using data from fixtures for Pokemon)
    @test_route = Route.create!(
      name: "Test Route",
      description: "A test route for catching Pokemon"
    )

    # Add some Pokemon to the route
    RouteEncounter.create!(route: @test_route, pokemon: pokemons(:bulbasaur), spawn_rate: 50)
    RouteEncounter.create!(route: @test_route, pokemon: pokemons(:charmander), spawn_rate: 30)
    RouteEncounter.create!(route: @test_route, pokemon: pokemons(:squirtle), spawn_rate: 20)
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
    assert_match "caught all", response.body.downcase
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
end
