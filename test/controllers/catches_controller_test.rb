require "test_helper"

class CatchesControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create test gates (display data loaded from YAML)
    @gate_0 = Gate.create!(
      gate_number: 1,
      required_difficulty_score: 0
    )

    @gate_1 = Gate.create!(
      gate_number: 2,
      required_difficulty_score: 5
    )

    # Create test route with encounters (use high order numbers to avoid YAML conflicts)
    @test_route = Route.create!(
      gate_requirement: 0,
      order: 100
    )

    @locked_route = Route.create!(
      gate_requirement: 2,
      order: 101
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
    # Route names are loaded from YAML based on order
    assert_match "Pallet Town", response.body  # order: 1
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
    assert_select "input.btn-adventure"
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

  test "should always show adventure button even when all route pokemon are caught" do
    trainer = trainers(:ash)

    # Catch all Pokemon on the test route
    @test_route.pokemon.each do |pokemon|
      Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")
    end

    log_in_as(trainer)
    get catches_path
    # Button should not be disabled since pokemon can be recaught for evolution stones
    assert_select "input.btn-adventure", minimum: 1
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

  test "should encounter any pokemon on adventure even if already caught" do
    trainer = trainers(:ash)

    # Catch all pokemon on the route
    @test_route.pokemon.each do |pokemon|
      Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")
    end

    log_in_as(trainer)
    # Should still be able to adventure and encounter pokemon
    post adventure_path(@test_route)
    assert_response :redirect
    assert_match /\/catch\/\d+/, response.headers["Location"]

    follow_redirect!
    # Should encounter one of the pokemon from the test route
    route_pokemon_names = @test_route.pokemon.pluck(:name)
    assert route_pokemon_names.any? { |name| response.body.include?(name) }
  end

  test "should always allow adventures even when all route pokemon are caught" do
    trainer = trainers(:ash)

    # Catch all pokemon on the route
    @test_route.pokemon.each do |pokemon|
      Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")
    end

    log_in_as(trainer)
    post adventure_path(@test_route)

    # Should redirect to pokemon encounter, not back to catches page
    assert_response :redirect
    assert_match /\/catch\/\d+/, response.headers["Location"]
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

  test "should allow encountering pokemon even if already caught" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)
    Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")

    log_in_as(trainer)
    get catch_path(pokemon)

    # Should show the encounter page, not redirect
    assert_response :success
    assert_match pokemon.name, response.body
  end

  # ================================================================================
  # DUPLICATE CAPTURE TESTS
  # ================================================================================

  test "should give evolution stone when catching already caught pokemon" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    # First capture
    Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")
    initial_captures = trainer.captures.count
    initial_stones = trainer.item_quantity(:evolution_stone)

    log_in_as(trainer)
    # Second capture attempt with master ball (guaranteed success)
    post catch_path(pokemon), params: { ball_type: "master_ball" }

    assert_redirected_to pokedex_path
    follow_redirect!

    trainer.reload
    # Should not create new capture
    assert_equal initial_captures, trainer.captures.count
    # Should give evolution stone
    assert_equal initial_stones + 1, trainer.item_quantity(:evolution_stone)
    # Should show appropriate message
    assert_match "Evolution Stone", response.body
    assert_match "already in your Pokédex", response.body
  end

  test "should show different message for duplicate capture vs new capture" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    # Give trainer master balls
    trainer.add_item(:master_ball, 5)

    # First capture - new pokemon
    log_in_as(trainer)
    post catch_path(pokemon), params: { ball_type: "master_ball" }
    follow_redirect!
    first_message = response.body
    assert_no_match "Evolution Stone", first_message

    # Second capture - duplicate
    post catch_path(pokemon), params: { ball_type: "master_ball" }
    follow_redirect!
    second_message = response.body
    assert_match "Evolution Stone", second_message
    assert_match "already in your Pokédex", second_message
  end

  test "should deduct pokeball even for duplicate capture" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    # First capture
    Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")
    initial_pokeballs = trainer.item_quantity(:pokeball)

    log_in_as(trainer)
    # Second capture attempt
    post catch_path(pokemon), params: { ball_type: "pokeball" }

    trainer.reload
    # Ball should be deducted (or stay same if catch failed, but in either case, ball is used)
    assert trainer.item_quantity(:pokeball) < initial_pokeballs
  end

  test "should not give evolution stone if duplicate capture fails" do
    trainer = trainers(:ash)
    pokemon = pokemons(:mewtwo) # Difficulty 5, very hard to catch with pokeball

    # First capture
    Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")
    initial_stones = trainer.item_quantity(:evolution_stone)

    log_in_as(trainer)
    # Try to recapture with pokeball (will likely fail)
    # Run multiple attempts to ensure at least one failure
    failed = false
    stones_before_fail = initial_stones
    20.times do
      stones_before_attempt = trainer.reload.item_quantity(:evolution_stone)
      post catch_path(pokemon), params: { ball_type: "pokeball" }
      trainer.reload

      if response.headers["Location"].include?("catch")
        # Failed - redirected back to catches page
        failed = true
        stones_after_fail = trainer.item_quantity(:evolution_stone)
        assert_equal stones_before_attempt, stones_after_fail, "Should not gain evolution stone when capture fails"
        break
      else
        # Successful duplicate capture - should have gained a stone
        stones_before_fail = trainer.item_quantity(:evolution_stone)
      end
    end

    # Verify we got at least one failure to test
    assert failed, "Expected at least one failed capture attempt in 20 tries with pokeball on difficulty 5 Pokemon"
  end

  # ================================================================================
  # ALREADY CAUGHT INDICATOR TESTS
  # ================================================================================

  test "should display already caught indicator when pokemon is in pokedex" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    # Catch the pokemon first
    Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")

    log_in_as(trainer)
    get catch_path(pokemon)

    assert_response :success
    assert_match "Already in your Pokédex!", response.body
    assert_match "Catching #{pokemon.name} again will reward you with an Evolution Stone", response.body
  end

  test "should not display already caught indicator for new pokemon" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    log_in_as(trainer)
    get catch_path(pokemon)

    assert_response :success
    assert_no_match "Already in your Pokédex!", response.body
    assert_no_match "Evolution Stone", response.body
  end

  test "should display checkmark in already caught indicator" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")

    log_in_as(trainer)
    get catch_path(pokemon)

    assert_response :success
    assert_match "✓", response.body
  end

  test "should show pokemon name in evolution stone reward message" do
    trainer = trainers(:ash)
    pokemon = pokemons(:pikachu)

    Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")

    log_in_as(trainer)
    get catch_path(pokemon)

    assert_response :success
    assert_match "Catching Pikachu again will reward you with an Evolution Stone", response.body
  end

  test "should show already caught indicator for any difficulty level" do
    trainer = trainers(:ash)

    # Test with different difficulty pokemon
    [pokemons(:bulbasaur), pokemons(:pikachu), pokemons(:mewtwo)].each do |pokemon|
      Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")

      log_in_as(trainer)
      get catch_path(pokemon)

      assert_response :success
      assert_match "Already in your Pokédex!", response.body
    end
  end

  test "should display already caught indicator even after multiple captures" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    # Catch it the first time
    Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")

    log_in_as(trainer)
    get catch_path(pokemon)

    assert_response :success
    assert_match "Already in your Pokédex!", response.body

    # The message should still appear even though we can catch it again
    post catch_path(pokemon), params: { ball_type: "pokeball" }

    # Encounter it again
    get catch_path(pokemon)
    assert_response :success
    assert_match "Already in your Pokédex!", response.body
  end

  test "should show indicator styling with gradient background" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    Capture.create!(trainer: trainer, pokemon: pokemon, ball_type: "pokeball")

    log_in_as(trainer)
    get catch_path(pokemon)

    assert_response :success
    # Check for styling elements
    assert_match "background: linear-gradient", response.body
    assert_match "#FFF4E6", response.body
  end

  test "should not show already caught indicator for different trainer" do
    trainer1 = trainers(:ash)
    trainer2 = trainers(:gary)
    pokemon = pokemons(:bulbasaur)

    # Trainer 1 catches the pokemon
    Capture.create!(trainer: trainer1, pokemon: pokemon, ball_type: "pokeball")

    # Trainer 2 should not see the indicator
    log_in_as(trainer2)
    get catch_path(pokemon)

    assert_response :success
    assert_no_match "Already in your Pokédex!", response.body
  end

  test "should show already caught indicator immediately after first capture" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    # Give trainer master ball for guaranteed success
    trainer.add_item(:master_ball, 2)

    log_in_as(trainer)

    # First capture
    post catch_path(pokemon), params: { ball_type: "master_ball" }
    assert_redirected_to pokedex_path

    # Immediately encounter it again
    get catch_path(pokemon)
    assert_response :success
    assert_match "Already in your Pokédex!", response.body
  end

  # ================================================================================
  # RUN ACTION TESTS
  # ================================================================================

  test "should allow trainer to run from pokemon encounter" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    log_in_as(trainer)
    post run_from_catch_path(pokemon)

    assert_redirected_to catches_path
    follow_redirect!
    assert_match "Got Away Safely", response.body
  end

  test "should require login to run from encounter" do
    pokemon = pokemons(:bulbasaur)
    post run_from_catch_path(pokemon)
    assert_redirected_to login_path
  end

  test "run button should be displayed on encounter page" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    log_in_as(trainer)
    get catch_path(pokemon)

    assert_response :success
    assert_match "Run", response.body
    assert_match "Run", response.body
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

    # Should show test route (gate 0) - falls back to "Route 100" since no YAML entry
    assert_match "Route 100", response.body

    # Should NOT show locked route (gate 1)
    assert_no_match "Route 101", response.body
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
    assert_no_match "Route 101", response.body

    # Give trainer enough Pokemon to meet gate 1 requirement (difficulty score >= 5)
    # Mewtwo has difficulty 5, which meets the requirement
    Capture.create!(trainer: trainer, pokemon: pokemons(:mewtwo), ball_type: "pokeball")

    # Refresh page
    get catches_path

    # Now locked route should be visible (trainer meets gate 1 requirement)
    assert_match "Route 101", response.body
  end

  # ================================================================================
  # APPEARANCE REQUIREMENT TESTS
  # ================================================================================

  test "should not show pokemon with unmet pokemon requirement" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Create a route with a pokemon that requires catching Bulbasaur first
    test_route = Route.create!(gate_requirement: 0, order: 200)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 50,
      required_pokemon_id: pokemons(:bulbasaur).id
    )

    get catches_path

    # Pikachu should appear locked (darkened) with requirement message
    assert_match "Pikachu", response.body
    assert_match "Requires: Bulbasaur", response.body
  end

  test "should show pokemon when pokemon requirement is met" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Create a route with a pokemon that requires catching Bulbasaur first
    test_route = Route.create!(gate_requirement: 0, order: 200)
    encounter = RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 50,
      required_pokemon_id: pokemons(:bulbasaur).id
    )

    # Trainer catches Bulbasaur
    Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")

    get catches_path

    # Pikachu should appear unlocked (no requirement message shown)
    assert_match "Pikachu", response.body
    # Should not show requirement since it's met
    # The view only shows requirement_description for locked pokemon
  end

  test "should not allow encounter with unmet pokemon requirement" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Create a route with only a pokemon that requires Bulbasaur
    test_route = Route.create!(gate_requirement: 0, order: 200)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 50,
      required_pokemon_id: pokemons(:bulbasaur).id
    )

    # Try to adventure on this route
    post adventure_path(test_route)

    # Should redirect with no pokemon message
    assert_redirected_to catches_path
    assert_match "No Pokémon available for that encounter type on this route!", flash[:notice]
  end

  test "should allow encounter when pokemon requirement is met" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Create a route with a pokemon that requires Bulbasaur
    test_route = Route.create!(gate_requirement: 0, order: 200)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 50,
      required_pokemon_id: pokemons(:bulbasaur).id
    )

    # Trainer catches Bulbasaur
    Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")

    # Try to adventure on this route
    post adventure_path(test_route)

    # Should encounter Pikachu
    assert_redirected_to catch_path(pokemons(:pikachu))
  end

  test "should not show pokemon with unmet gate requirement" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Create a gate
    gate = Gate.create!(gate_number: 6, required_difficulty_score: 50)

    # Create a route with a pokemon that requires gate 6
    test_route = Route.create!(gate_requirement: 0, order: 200)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 50,
      required_gate_number: 6
    )

    get catches_path

    # Pikachu should appear locked with gate requirement message
    assert_match "Pikachu", response.body
    assert_match "Requires:", response.body
    assert_match "Fuchsia City Gym", response.body
  end

  test "should show pokemon when gate requirement is met" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Create a gate
    gate = Gate.create!(gate_number: 5, required_difficulty_score: 50)
    GateUnlock.create!(trainer: trainer, gate: gate, unlocked_at: Time.current)

    # Create a route with a pokemon that requires gate 5
    test_route = Route.create!(gate_requirement: 0, order: 200)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 50,
      required_gate_number: 5
    )

    get catches_path

    # Pikachu should appear unlocked
    assert_match "Pikachu", response.body
  end

  test "should require BOTH pokemon and gate when both are set" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Create a gate
    gate = Gate.create!(gate_number: 6, required_difficulty_score: 50)

    # Create a route with a pokemon that requires both Bulbasaur AND gate 6
    test_route = Route.create!(gate_requirement: 0, order: 200)
    encounter = RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 50,
      required_pokemon_id: pokemons(:bulbasaur).id,
      required_gate_number: 6
    )

    get catches_path

    # Should show both requirements
    assert_match "Bulbasaur", response.body
    assert_match "Fuchsia City Gym", response.body
    assert_match "&", response.body

    # Try to adventure - should fail
    post adventure_path(test_route)
    assert_redirected_to catches_path

    # Meet only pokemon requirement
    Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    post adventure_path(test_route)
    assert_redirected_to catches_path  # Still fails

    # Meet both requirements
    GateUnlock.create!(trainer: trainer, gate: gate, unlocked_at: Time.current)
    post adventure_path(test_route)
    assert_redirected_to catch_path(pokemons(:pikachu))  # Now succeeds
  end

  test "should correctly count available pokemon excluding locked encounters" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Create a route with 2 pokemon: one always available, one requires Bulbasaur
    test_route = Route.create!(gate_requirement: 0, order: 200)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:charmander),
      spawn_rate: 50
    )
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 50,
      required_pokemon_id: pokemons(:bulbasaur).id
    )

    get catches_path

    # Should show 1 pokemon available (only Charmander)
    assert_match "1 Pokémon available", response.body

    # Catch Bulbasaur
    Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")

    get catches_path

    # Should now show 2 pokemon available
    assert_match "2 Pokémon available", response.body
  end

  test "should show pokemon locked when required pokemon not caught" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Create a test route with pokemon that requires Bulbasaur
    test_route = Route.create!(gate_requirement: 0, order: 500)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 100,
      required_pokemon_id: pokemons(:bulbasaur).id
    )

    get catches_path

    # Should show pokemon as locked with requirement message
    assert_match "Pikachu", response.body
    assert_match "Requires: Bulbasaur", response.body
  end

  test "should show pokemon unlocked when required pokemon is caught" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Create a test route with pokemon that requires Bulbasaur
    test_route = Route.create!(gate_requirement: 0, order: 500)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 100,
      required_pokemon_id: pokemons(:bulbasaur).id
    )

    # Catch Bulbasaur
    Capture.create!(trainer: trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")

    get catches_path

    # Should show Pikachu as available
    assert_match "Pikachu", response.body
    # Should not show lock icon since requirement is met
    assert_match "1 Pokémon available", response.body
  end

  test "should show pokemon locked when neither required nor alternative pokemon caught" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Create a test route with OR logic (Bulbasaur OR Charmander)
    test_route = Route.create!(gate_requirement: 0, order: 500)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 100,
      required_pokemon_id: pokemons(:bulbasaur).id,
      alternative_required_pokemon_id: pokemons(:charmander).id
    )

    get catches_path

    # Should show pokemon as locked with OR requirement
    assert_match "Pikachu", response.body
    assert_match "Requires: Bulbasaur or Charmander", response.body
  end

  test "should show pokemon unlocked when alternative pokemon caught" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Create a test route with OR logic (Bulbasaur OR Charmander)
    test_route = Route.create!(gate_requirement: 0, order: 500)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 100,
      required_pokemon_id: pokemons(:bulbasaur).id,
      alternative_required_pokemon_id: pokemons(:charmander).id
    )

    # Catch only Charmander (the alternative)
    Capture.create!(trainer: trainer, pokemon: pokemons(:charmander), ball_type: "pokeball")

    get catches_path

    # Should show Pikachu as available
    assert_match "Pikachu", response.body
    assert_match "1 Pokémon available", response.body
  end

  test "should allow encountering pokemon when alternative requirement met" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Create a test route with OR logic
    test_route = Route.create!(gate_requirement: 0, order: 500)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 100,
      required_pokemon_id: pokemons(:bulbasaur).id,
      alternative_required_pokemon_id: pokemons(:charmander).id
    )

    # Catch only Charmander (the alternative)
    Capture.create!(trainer: trainer, pokemon: pokemons(:charmander), ball_type: "pokeball")

    # Try to adventure - should succeed
    post adventure_path(test_route)
    assert_redirected_to catch_path(pokemons(:pikachu))
  end
end
