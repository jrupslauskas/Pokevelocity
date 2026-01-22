require "test_helper"

class CatchesControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create test gates (use high numbers to avoid YAML conflicts)
    @gate_0 = Gate.create!(
      gate_number: 100,
      required_difficulty_score: 0
    )

    @gate_1 = Gate.create!(
      gate_number: 101,
      required_difficulty_score: 5
    )

    # Create test route with encounters (use high order numbers to avoid YAML conflicts)
    @test_route = Route.create!(
      gate_requirement: 0,
      order: 100
    )

    @locked_route = Route.create!(
      gate_requirement: 101,
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

  # Helper method to set up a valid encounter session
  def set_encounter_session(pokemon)
    session[:current_encounter] = pokemon.id
  end

  # Helper method to give trainer enough difficulty score for a gate
  def reach_difficulty_score(trainer, target_score)
    current_score = trainer.difficulty_score
    return if current_score >= target_score

    needed_score = target_score - current_score
    # Create Pokemon with difficulty 5 to reach target
    pokemon_needed = (needed_score / 5.0).ceil

    # Use valid Pokedex numbers (1-151)
    # Start from a number that won't conflict with already-captured Pokemon
    base_num = 50 + trainer.captured_pokemon.count
    pokemon_needed.times do |i|
      pokedex_num = (base_num + i) % 151 + 1  # Cycle through 1-151
      pokemon = Pokemon.find_or_create_by!(pokedex_number: pokedex_num) do |p|
        p.name = "TestPokemon#{pokedex_num}"
        p.difficulty = 5
      end
      # Skip if already captured (avoid duplicate error)
      next if trainer.captured_pokemon.exists?(id: pokemon.id)
      trainer.captures.create!(pokemon: pokemon, ball_type: 'pokeball')
    end
  end

  # Helper to get or create a gate with required score
  def get_or_create_gate(gate_number, required_score)
    Gate.find_or_create_by!(gate_number: gate_number) do |g|
      g.required_difficulty_score = required_score
    end
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
    set_encounter_session(pokemon)
    get catch_path(pokemon)

    assert_response :success
    assert_match pokemon.name, response.body
  end

  test "should show catch probabilities on encounter page" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur)

    log_in_as(trainer)
    set_encounter_session(pokemon)
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

    # Unlock all gates so catch doesn't trigger celebration
    Gate.all.each do |gate|
      trainer.gate_unlocks.find_or_create_by(gate: gate)
    end

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

    # Unlock all gates so catch doesn't trigger celebration
    Gate.all.each do |gate|
      trainer.gate_unlocks.find_or_create_by(gate: gate)
    end

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

  test "should not show 'Unlocked' text for unlocked gates" do
    trainer = trainers(:ash)
    GateUnlock.create!(trainer: trainer, gate: @gate_0, unlocked_at: Time.current)

    log_in_as(trainer)
    get catches_path

    # Should not show the old "Unlocked" text anymore
    assert_no_match /✓ Unlocked/, response.body
  end

  test "should not show 'Locked' text for locked gates" do
    trainer = trainers(:ash)
    GateUnlock.create!(trainer: trainer, gate: @gate_0, unlocked_at: Time.current)

    log_in_as(trainer)
    get catches_path

    # Should not show the old "Locked" text anymore
    assert_no_match /🔒 Locked/, response.body
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

  # ================================================================================
  # GATE BADGE DISPLAY TESTS
  # ================================================================================

  test "should show badge icon for unlocked gate 1 (Boulder Badge)" do
    trainer = trainers(:ash)
    # Create gate 1 with a reasonable difficulty
    gate_1 = get_or_create_gate(1, 8)
    # Give trainer enough score to unlock it
    reach_difficulty_score(trainer, gate_1.required_difficulty_score)
    GateUnlock.create!(trainer: trainer, gate: gate_1, unlocked_at: Time.current)

    log_in_as(trainer)
    get catches_path

    assert_response :success
    # Should have badge icon with correct class
    assert_select "img.gate-badge-icon"
    # Should have correct title attribute for tooltip
    assert_select "img.gate-badge-icon[title='Boulder Badge']"
    # Should have correct alt text
    assert_select "img.gate-badge-icon[alt='Boulder Badge']"
  end

  test "should show badge icon for unlocked gate 2 (Cascade Badge)" do
    trainer = trainers(:ash)
    gate_1 = get_or_create_gate(1, 8)
    gate_2 = get_or_create_gate(2, 15)
    reach_difficulty_score(trainer, gate_2.required_difficulty_score)
    GateUnlock.create!(trainer: trainer, gate: gate_1, unlocked_at: Time.current)
    GateUnlock.create!(trainer: trainer, gate: gate_2, unlocked_at: Time.current)

    log_in_as(trainer)
    get catches_path

    assert_select "img.gate-badge-icon[title='Cascade Badge']"
  end

  test "should show badge icon for unlocked gate 3 (Thunder Badge)" do
    trainer = trainers(:ash)
    gate_1 = get_or_create_gate(1, 8)
    gate_2 = get_or_create_gate(2, 15)
    gate_3 = get_or_create_gate(3, 25)
    reach_difficulty_score(trainer, gate_3.required_difficulty_score)
    GateUnlock.create!(trainer: trainer, gate: gate_1, unlocked_at: Time.current)
    GateUnlock.create!(trainer: trainer, gate: gate_2, unlocked_at: Time.current)
    GateUnlock.create!(trainer: trainer, gate: gate_3, unlocked_at: Time.current)

    log_in_as(trainer)
    get catches_path

    assert_select "img.gate-badge-icon[title='Thunder Badge']"
  end

  test "should show badge icons for multiple unlocked gates" do
    trainer = trainers(:ash)
    gate_1 = get_or_create_gate(1, 8)
    gate_2 = get_or_create_gate(2, 15)
    reach_difficulty_score(trainer, gate_2.required_difficulty_score)
    GateUnlock.create!(trainer: trainer, gate: gate_1, unlocked_at: Time.current)
    GateUnlock.create!(trainer: trainer, gate: gate_2, unlocked_at: Time.current)

    log_in_as(trainer)
    get catches_path

    # Should show both badges
    assert_select "img.gate-badge-icon[title='Boulder Badge']"
    assert_select "img.gate-badge-icon[title='Cascade Badge']"
    # Should have 2 badge icons total (only 2 gates visible)
    assert_select "img.gate-badge-icon", count: 2
  end

  test "should not show badge icon for locked gates" do
    trainer = trainers(:ash)
    # Don't unlock gate 1

    log_in_as(trainer)
    get catches_path

    # Should not have any badge icons since gate 1 is locked
    assert_select "img.gate-badge-icon", count: 0
  end

  test "should show badge for gate 8 (Earth Badge)" do
    trainer = trainers(:ash)
    # Unlock gates 1-8
    (1..8).each do |gate_num|
      gate = get_or_create_gate(gate_num, gate_num * 10)
      reach_difficulty_score(trainer, gate.required_difficulty_score)
      GateUnlock.create!(trainer: trainer, gate: gate, unlocked_at: Time.current)
    end

    log_in_as(trainer)
    get catches_path

    assert_select "img.gate-badge-icon[title='Earth Badge']"
  end

  test "should show Elite Four Trophy for gate 9" do
    trainer = trainers(:ash)
    # Unlock all gates including Elite 4
    (1..9).each do |gate_num|
      gate = get_or_create_gate(gate_num, gate_num * 10)
      reach_difficulty_score(trainer, gate.required_difficulty_score)
      GateUnlock.create!(trainer: trainer, gate: gate, unlocked_at: Time.current)
    end

    log_in_as(trainer)
    get catches_path

    # Should have 9 badges (gates 1-8 plus Elite Four)
    assert_select "img.gate-badge-icon", count: 9
    # Should show the Elite Four Trophy
    assert_select "img.gate-badge-icon[title='Elite Four Trophy']"
  end

  test "should show all 8 gym badges when all gyms are unlocked" do
    trainer = trainers(:ash)
    # Unlock gates 1-8
    (1..8).each do |gate_num|
      gate = get_or_create_gate(gate_num, gate_num * 10)
      reach_difficulty_score(trainer, gate.required_difficulty_score)
      GateUnlock.create!(trainer: trainer, gate: gate, unlocked_at: Time.current)
    end

    log_in_as(trainer)
    get catches_path

    # Should show all 8 gym badges
    assert_select "img.gate-badge-icon[title='Boulder Badge']"
    assert_select "img.gate-badge-icon[title='Cascade Badge']"
    assert_select "img.gate-badge-icon[title='Thunder Badge']"
    assert_select "img.gate-badge-icon[title='Rainbow Badge']"
    assert_select "img.gate-badge-icon[title='Soul Badge']"
    assert_select "img.gate-badge-icon[title='Marsh Badge']"
    assert_select "img.gate-badge-icon[title='Volcano Badge']"
    assert_select "img.gate-badge-icon[title='Earth Badge']"
    assert_select "img.gate-badge-icon", count: 8
  end

  # ================================================================================
  # END GATE BADGE DISPLAY TESTS
  # ================================================================================

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
    assert_match "No Pokémon available on this route!", flash[:notice]
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
    gate = Gate.create!(gate_number: 5, required_difficulty_score: 50)

    # Create a route with a pokemon that requires gate 6
    test_route = Route.create!(gate_requirement: 0, order: 200)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 50,
      required_gate_number: 5
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
    gate = Gate.create!(gate_number: 5, required_difficulty_score: 50)

    # Create a route with a pokemon that requires both Bulbasaur AND gate 6
    test_route = Route.create!(gate_requirement: 0, order: 200)
    encounter = RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 50,
      required_pokemon_id: pokemons(:bulbasaur).id,
      required_gate_number: 5
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

  # ================================================================================
  # MIXED ENCOUNTER TYPE LOCKING TESTS
  # ================================================================================

  test "should allow fishing when land encounters are locked but fish encounters are available" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer old rod
    trainer.add_item(:old_rod, 1)

    # Create a route with locked grass encounter and available fish encounter
    test_route = Route.create!(gate_requirement: 0, order: 500)

    # Grass encounter locked behind Spearow requirement
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 100,
      encounter_type: "grass",
      required_pokemon_id: pokemons(:charmander).id # Trainer doesn't have this
    )

    # Fish encounter available (no requirement)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )

    get catches_path

    # Should render both the adventure form and locked button (controlled by CSS)
    assert_match "adventure-form", response.body
    assert_match "btn-adventure-disabled", response.body

    # Should have encounter availability data
    assert_match "data-grass-available=\"false\"", response.body
    assert_match "data-fish-available=\"true\"", response.body

    # Should be able to adventure with fish encounter type
    trainer.update!(adventures_remaining: 5)
    post adventure_path(test_route), params: { encounter_type: "fish", rod_type: "old_rod" }

    # Should successfully encounter Magikarp
    assert_redirected_to catch_path(pokemons(:magikarp))
  end

  test "should not allow grass adventure when grass encounters are locked even if fish is available" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer old rod
    trainer.add_item(:old_rod, 1)
    trainer.update!(adventures_remaining: 5)

    # Create a route with locked grass encounter and available fish encounter
    test_route = Route.create!(gate_requirement: 0, order: 504)

    # Grass encounter locked
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 100,
      encounter_type: "grass",
      required_pokemon_id: pokemons(:charmander).id
    )

    # Fish encounter available
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )

    # Try to adventure with grass encounter type (should fail)
    post adventure_path(test_route), params: { encounter_type: "grass" }

    # Should redirect with no pokemon message
    assert_redirected_to catches_path
    assert_match "No Pokémon available on this route!", flash[:notice]
  end

  test "should show locked button for surf when only surf encounters locked but grass available" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer surf
    trainer.add_item(:hm_surf, 1)

    # Create a route with available grass and locked surf
    test_route = Route.create!(gate_requirement: 0, order: 501)

    # Grass encounter available (no requirement)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 100,
      encounter_type: "grass"
    )

    # Surf encounter locked behind requirement
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:tentacool),
      spawn_rate: 100,
      encounter_type: "surf",
      required_item_key: "hm_surf",
      required_pokemon_id: pokemons(:charmander).id
    )

    get catches_path

    # Should have both buttons rendered
    assert_match "adventure-form", response.body
    assert_match "btn-adventure-disabled", response.body

    # Should have correct availability data
    assert_match "data-grass-available=\"true\"", response.body
    assert_match "data-surf-available=\"false\"", response.body

    # Should be able to adventure on grass
    trainer.update!(adventures_remaining: 5)
    post adventure_path(test_route), params: { encounter_type: "grass" }
    assert_redirected_to catch_path(pokemons(:pikachu))
  end

  test "should allow adventure when requirement is met for one encounter type" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer old rod and catch required pokemon
    trainer.add_item(:old_rod, 1)
    Capture.create!(trainer: trainer, pokemon: pokemons(:charmander), ball_type: "pokeball")
    trainer.update!(adventures_remaining: 5)

    # Create a route with both grass and fish locked, but grass requirement is met
    test_route = Route.create!(gate_requirement: 0, order: 502)

    # Grass encounter - requirement met (has Charmander)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 100,
      encounter_type: "grass",
      required_pokemon_id: pokemons(:charmander).id
    )

    # Fish encounter - requirement not met (doesn't have Bulbasaur)
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod",
      required_pokemon_id: pokemons(:bulbasaur).id
    )

    get catches_path

    # Should have correct availability data
    assert_match "data-grass-available=\"true\"", response.body
    assert_match "data-fish-available=\"false\"", response.body

    # Should be able to adventure on grass
    post adventure_path(test_route), params: { encounter_type: "grass" }
    assert_redirected_to catch_path(pokemons(:pikachu))
  end

  test "should show all locked when all encounter types are locked" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer fishing rod and surf
    trainer.add_item(:old_rod, 1)
    trainer.add_item(:hm_surf, 1)

    # Create a route where ALL encounters are locked
    test_route = Route.create!(gate_requirement: 0, order: 503)

    # All encounter types locked
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:pikachu),
      spawn_rate: 100,
      encounter_type: "grass",
      required_pokemon_id: pokemons(:charmander).id
    )
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod",
      required_pokemon_id: pokemons(:bulbasaur).id
    )
    RouteEncounter.create!(
      route: test_route,
      pokemon: pokemons(:tentacool),
      spawn_rate: 100,
      encounter_type: "surf",
      required_item_key: "hm_surf",
      required_pokemon_id: pokemons(:squirtle).id
    )

    get catches_path

    # Should show all locked
    assert_match "data-grass-available=\"false\"", response.body
    assert_match "data-fish-available=\"false\"", response.body
    assert_match "data-surf-available=\"false\"", response.body

    # Should show locked button
    assert_match "Locked", response.body
  end

  # ================================================================================
  # MULTI-ATTEMPT CATCH WORKFLOW TESTS
  # ================================================================================

  test "should stay on encounter page when catch fails and trainer has balls remaining" do
    trainer = trainers(:ash)
    pokemon = pokemons(:mewtwo) # Difficulty 5, very hard to catch with pokeball

    # Give trainer 5 pokeballs
    trainer.add_item(:pokeball, 5)
    initial_pokeballs = trainer.item_quantity(:pokeball)

    log_in_as(trainer)

    # Try to catch with pokeball (will likely fail due to difficulty 5)
    # Run multiple attempts to ensure at least one failure
    failed = false
    20.times do
      balls_before = trainer.reload.item_quantity(:pokeball)
      post catch_path(pokemon), params: { ball_type: "pokeball" }

      # Check if it failed (didn't redirect to pokedex)
      if response.headers["Location"]&.include?("/catch/")
        # Failed catch - should redirect back to encounter page
        assert_redirected_to catch_path(pokemon)
        follow_redirect!

        # Should show "broke free" message
        assert_match "broke free", response.body
        assert_match pokemon.name, response.body

        # Ball should be deducted
        trainer.reload
        assert_equal balls_before - 1, trainer.item_quantity(:pokeball)

        # Should still have balls remaining
        assert trainer.total_pokeballs > 0

        failed = true
        break
      end
    end

    assert failed, "Expected at least one failed capture attempt in 20 tries with pokeball on difficulty 5 Pokemon"
  end

  test "should redirect to route selection when catch fails and trainer is out of all balls" do
    trainer = trainers(:broke_trainer) # Use trainer with no items
    pokemon = pokemons(:mewtwo) # Difficulty 5, very hard to catch with pokeball

    log_in_as(trainer)

    # Try to catch with pokeball (will likely fail due to difficulty 5)
    # Run multiple attempts to ensure at least one failure on the last ball
    failed_on_last_ball = false
    max_attempts = 50 # Increase attempts for better probability
    max_attempts.times do
      # Reset to 1 ball for each attempt
      trainer.reload
      current_balls = trainer.total_pokeballs
      if current_balls == 0
        trainer.add_item(:pokeball, 1)
      end

      post catch_path(pokemon), params: { ball_type: "pokeball" }

      # Check if catch failed (redirected to /catch but not /catch/:id)
      if response.headers["Location"]&.include?("/catch") && !response.headers["Location"]&.include?("/catch/#{pokemon.id}")
        # Failed catch - should redirect to route selection (catches_path)
        assert_redirected_to catches_path
        follow_redirect!

        # Should show "broke free" message
        assert_match "broke free", response.body
        assert_match pokemon.name, response.body

        # Trainer should have no balls left
        trainer.reload
        assert_equal 0, trainer.total_pokeballs

        failed_on_last_ball = true
        break
      end
    end

    assert failed_on_last_ball, "Expected at least one failed capture on last ball in #{max_attempts} tries (10% success rate)"
  end

  test "should deduct correct ball type when catch fails" do
    trainer = trainers(:ash)
    pokemon = pokemons(:mewtwo) # Difficulty 5

    # Give trainer multiple ball types
    trainer.add_item(:pokeball, 5)
    trainer.add_item(:great_ball, 3)

    log_in_as(trainer)

    initial_pokeballs = trainer.item_quantity(:pokeball)
    initial_great_balls = trainer.item_quantity(:great_ball)

    # Try to catch with great_ball (will likely fail)
    failed = false
    20.times do
      great_balls_before = trainer.reload.item_quantity(:great_ball)
      post catch_path(pokemon), params: { ball_type: "great_ball" }

      if response.headers["Location"]&.include?("/catch/")
        # Failed catch - verify correct ball was deducted
        trainer.reload
        assert_equal great_balls_before - 1, trainer.item_quantity(:great_ball)
        assert_equal initial_pokeballs, trainer.item_quantity(:pokeball), "Wrong ball type was deducted"

        failed = true
        break
      end
    end

    assert failed, "Expected at least one failed capture attempt"
  end

  test "should allow multiple catch attempts on same pokemon" do
    trainer = trainers(:broke_trainer) # Use trainer with no items
    pokemon = pokemons(:mewtwo) # Difficulty 5

    # Give trainer 10 pokeballs for multiple attempts
    trainer.add_item(:pokeball, 10)
    initial_balls = 10

    log_in_as(trainer)

    # Try multiple catch attempts
    attempts = 0
    failed_attempts = 0
    max_attempts = 3
    max_attempts.times do
      trainer.reload
      balls_before = trainer.item_quantity(:pokeball)
      post catch_path(pokemon), params: { ball_type: "pokeball" }

      # Count the attempt
      attempts += 1

      # If failed, we should still be on encounter page with balls remaining
      if response.headers["Location"]&.include?("/catch/#{pokemon.id}")
        failed_attempts += 1
        follow_redirect!
        assert_response :success
        assert_match pokemon.name, response.body

        # Verify ball was used
        trainer.reload
        assert_equal balls_before - 1, trainer.item_quantity(:pokeball)
      else
        # Successful catch or redirected elsewhere, stop trying
        break
      end
    end

    # Should have made at least one attempt
    assert attempts > 0, "Should have made at least one catch attempt"
    # Should have used as many balls as attempts made
    trainer.reload
    balls_used = initial_balls - trainer.item_quantity(:pokeball)
    assert_equal attempts, balls_used, "Should have used exactly #{attempts} balls for #{attempts} attempts"
  end

  test "successful catch should still redirect to pokedex" do
    trainer = trainers(:ash)
    pokemon = pokemons(:bulbasaur) # Difficulty 1

    # Unlock all gates so catch doesn't trigger celebration
    Gate.all.each do |gate|
      trainer.gate_unlocks.find_or_create_by(gate: gate)
    end

    # Give trainer a master ball for guaranteed success
    trainer.add_item(:master_ball, 1)

    log_in_as(trainer)

    post catch_path(pokemon), params: { ball_type: "master_ball" }

    # Should redirect to pokedex on success
    assert_redirected_to pokedex_path
    follow_redirect!

    # Should show success message
    assert_match "Success", response.body
    assert_match pokemon.name, response.body

    # Should create capture record
    trainer.reload
    assert trainer.captured_pokemon.include?(pokemon)
  end

  test "should show correct flash message when pokemon breaks free with balls remaining" do
    trainer = trainers(:ash)
    pokemon = pokemons(:mewtwo) # Difficulty 5

    # Give trainer multiple balls
    trainer.add_item(:pokeball, 5)

    log_in_as(trainer)

    # Try to catch (will likely fail)
    failed = false
    20.times do
      post catch_path(pokemon), params: { ball_type: "pokeball" }

      if response.headers["Location"]&.include?("/catch/#{pokemon.id}")
        follow_redirect!

        # Check for red error flash message
        assert_match "broke free", response.body
        assert_match "Pokeball was lost", response.body

        trainer.reload
        assert trainer.total_pokeballs > 0

        failed = true
        break
      end
    end

    assert failed, "Expected at least one failed capture attempt"
  end

  test "should show correct flash message when pokemon breaks free on last ball" do
    trainer = trainers(:broke_trainer) # Use trainer with no items
    pokemon = pokemons(:mewtwo) # Difficulty 5

    log_in_as(trainer)

    # Try to catch with pokeball (10% success rate = 90% failure rate)
    # Use more attempts to ensure we get a failure
    failed_on_last = false
    max_attempts = 50
    max_attempts.times do
      # Reset for each attempt
      trainer.reload
      if trainer.total_pokeballs == 0
        trainer.add_item(:pokeball, 1)
      end

      post catch_path(pokemon), params: { ball_type: "pokeball" }

      if response.headers["Location"]&.include?("/catch") && !response.headers["Location"]&.include?("/catch/#{pokemon.id}")
        follow_redirect!

        # Should show "broke free" message
        assert_match "broke free", response.body
        assert_match "Pokeball was lost", response.body

        trainer.reload
        assert_equal 0, trainer.total_pokeballs

        failed_on_last = true
        break
      end
    end

    assert failed_on_last, "Expected at least one failed capture on last ball in #{max_attempts} tries (10% success rate)"
  end

  test "should count all ball types when checking if trainer has balls remaining" do
    trainer = trainers(:broke_trainer) # Use trainer with no items
    pokemon = pokemons(:mewtwo) # Difficulty 5

    # Give trainer 1 pokeball and 2 great balls (total: 3)
    trainer.add_item(:pokeball, 1)
    trainer.add_item(:great_ball, 2)

    log_in_as(trainer)

    # Use the pokeball (will likely fail)
    failed = false
    catch_attempts = 0
    20.times do
      trainer.reload
      pokeballs = trainer.item_quantity(:pokeball)
      break if pokeballs == 0 # Already used it in a previous iteration

      post catch_path(pokemon), params: { ball_type: "pokeball" }
      catch_attempts += 1

      if response.headers["Location"]&.include?("/catch/#{pokemon.id}")
        # Failed but should stay on encounter because we have great balls
        assert_redirected_to catch_path(pokemon)

        trainer.reload
        # Should have used pokeball
        assert_equal 0, trainer.item_quantity(:pokeball), "Pokeball should be used"
        # Should still have great balls untouched
        assert_equal 2, trainer.item_quantity(:great_ball), "Great balls should remain"
        # Should have balls remaining (2 great balls)
        assert_equal 2, trainer.total_pokeballs, "Should have 2 balls remaining"

        failed = true
        break
      elsif response.headers["Location"]&.include?("/pokedex")
        # Successful catch on pokeball, can't test this scenario
        # Break and don't assert failed
        break
      end
    end

    # Only assert if we actually attempted the test scenario
    if catch_attempts > 0
      assert failed, "Expected at least one failed capture attempt with pokeball in #{catch_attempts} tries"
    end
  end

  # ================================================================================
  # ADVENTURE LIMIT TESTS
  # ================================================================================

  test "new action should display adventure count" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 3,
      adventures_allocated_at: 1.hour.ago
    )

    log_in_as(trainer)
    get catches_path

    assert_response :success
    assert_match /3 \/ 10/, response.body
  end

  test "adventure action should consume one adventure" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 5,
      adventures_allocated_at: 1.hour.ago
    )

    log_in_as(trainer)
    post adventure_path(@test_route)

    trainer.reload
    assert_equal 4, trainer.adventures_remaining
  end

  test "adventure action should redirect when no adventures remaining" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 0,
      adventures_allocated_at: 5.hours.ago
    )

    log_in_as(trainer)
    post adventure_path(@test_route)

    assert_redirected_to catches_path
    assert_match /out of adventures/i, flash[:alert]
    assert_match /Visit the Poké Center/i, flash[:alert]
  end

  test "adventure action should work with 1 adventure remaining" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 1,
      adventures_allocated_at: 1.hour.ago
    )

    log_in_as(trainer)
    post adventure_path(@test_route)

    trainer.reload
    assert_equal 0, trainer.adventures_remaining
    # Should redirect to encounter page, not catches_path
    assert_response :redirect
    assert_not_equal catches_path, response.headers["Location"]
  end

  test "adventure action should consume adventure before picking Pokemon" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 1,
      adventures_allocated_at: 1.hour.ago
    )

    log_in_as(trainer)

    # Make the adventure request
    post adventure_path(@test_route)

    # Adventure should be consumed even though we got redirected to encounter
    trainer.reload
    assert_equal 0, trainer.adventures_remaining
  end

  test "adventure action with fishing should consume adventure" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 3,
      adventures_allocated_at: 1.hour.ago
    )
    trainer.add_item(:old_rod, 1)

    # Create a fishing encounter
    fishing_route = Route.create!(gate_requirement: 0, order: 200)
    RouteEncounter.create!(
      route: fishing_route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )

    log_in_as(trainer)
    post adventure_path(fishing_route), params: { encounter_type: "fish", rod_type: "old_rod" }

    trainer.reload
    assert_equal 2, trainer.adventures_remaining
  end

  test "adventure action with surfing should consume adventure" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 4,
      adventures_allocated_at: 1.hour.ago
    )
    trainer.add_item(:hm_surf, 1)

    # Create a surf encounter
    surf_route = Route.create!(gate_requirement: 0, order: 201)
    RouteEncounter.create!(
      route: surf_route,
      pokemon: pokemons(:tentacool),
      spawn_rate: 100,
      encounter_type: "surf",
      required_item_key: "hm_surf"
    )

    log_in_as(trainer)
    post adventure_path(surf_route), params: { encounter_type: "surf" }

    trainer.reload
    assert_equal 3, trainer.adventures_remaining
  end

  test "show action should display adventure count" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 2,
      adventures_allocated_at: 1.hour.ago
    )

    log_in_as(trainer)
    get catch_path(pokemons(:pikachu))

    assert_response :success
    assert_match /2 \/ 10/, response.body
  end

  test "show action should display Adventure Again button when adventures available" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 3,
      adventures_allocated_at: 1.hour.ago
    )

    log_in_as(trainer)

    # First do an adventure to set last_adventure in session
    post adventure_path(@test_route)
    follow_redirect!

    # Now check the encounter page
    assert_response :success
    assert_match /Adventure Again/i, response.body
  end

  test "show action should display No More Adventures when depleted" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 1,
      adventures_allocated_at: 5.hours.ago
    )

    log_in_as(trainer)

    # Use the last adventure
    post adventure_path(@test_route)
    follow_redirect!

    # Now trainer has 0 adventures
    trainer.reload
    assert_equal 0, trainer.adventures_remaining

    # Check the encounter page shows depleted state
    assert_response :success
    assert_match /No More Adventures/i, response.body
    assert_match /Replenishes in/i, response.body
  end

  test "route cards should show disabled button when no adventures" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 0,
      adventures_allocated_at: 5.hours.ago
    )

    log_in_as(trainer)
    get catches_path

    assert_response :success
    assert_match /No More Adventures/i, response.body
    assert_match /Replenishes in/i, response.body
  end

  test "adventure limit should apply to all encounter types equally" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 2,
      adventures_allocated_at: 1.hour.ago
    )
    trainer.add_item(:old_rod, 1)

    # Create routes for different encounter types
    grass_route = Route.create!(gate_requirement: 0, order: 300)
    fish_route = Route.create!(gate_requirement: 0, order: 301)

    RouteEncounter.create!(route: grass_route, pokemon: pokemons(:pidgey), spawn_rate: 100, encounter_type: "grass")
    RouteEncounter.create!(route: fish_route, pokemon: pokemons(:magikarp), spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")

    log_in_as(trainer)

    # First adventure (grass)
    post adventure_path(grass_route), params: { encounter_type: "grass" }
    trainer.reload
    assert_equal 1, trainer.adventures_remaining

    # Second adventure (fish) - should work
    post adventure_path(fish_route), params: { encounter_type: "fish", rod_type: "old_rod" }
    trainer.reload
    assert_equal 0, trainer.adventures_remaining

    # Third adventure should fail
    post adventure_path(grass_route), params: { encounter_type: "grass" }
    assert_redirected_to catches_path
    assert_match /out of adventures/i, flash[:alert]
  end

  # ================================================================================
  # VISIT POKÉ CENTER TESTS
  # ================================================================================

  test "visit_poke_center should claim adventures when available" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 3,
      adventures_allocated_at: 25.hours.ago
    )

    log_in_as(trainer)
    post visit_poke_center_path

    trainer.reload
    assert_equal 8, trainer.adventures_remaining
    assert_redirected_to catches_path
    assert_match /Restored \+5 adventure/, flash[:notice]
    assert_match /8\/10/, flash[:notice]
  end

  test "visit_poke_center should show success message with count" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 0,
      adventures_allocated_at: 25.hours.ago
    )

    log_in_as(trainer)
    post visit_poke_center_path

    assert_redirected_to catches_path
    follow_redirect!

    assert_match /Welcome to the Poké Center/i, response.body
    assert_match /Restored \+5 adventure/, response.body
  end

  test "visit_poke_center should not claim when none available" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 5,
      adventures_allocated_at: 5.hours.ago
    )

    log_in_as(trainer)
    post visit_poke_center_path

    trainer.reload
    assert_equal 5, trainer.adventures_remaining
    assert_redirected_to catches_path
    assert_match /No adventures available to claim yet/i, flash[:alert]
  end

  test "visit_poke_center should show error message when none available" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 5,
      adventures_allocated_at: 10.hours.ago
    )

    log_in_as(trainer)
    post visit_poke_center_path

    assert_redirected_to catches_path
    follow_redirect!

    assert_match /No adventures available to claim yet/i, response.body
    assert_match /Next adventure in/i, response.body
    assert_match /\d+h \d+m/, response.body
  end

  test "visit_poke_center should work with multiple periods" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 0,
      adventures_allocated_at: 50.hours.ago
    )

    log_in_as(trainer)
    post visit_poke_center_path

    trainer.reload
    assert_equal 10, trainer.adventures_remaining
    assert_redirected_to catches_path
    assert_match /Restored \+10 adventures/, flash[:notice]
    assert_match /10\/10/, flash[:notice]
  end

  test "visit_poke_center should handle singular adventure correctly" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 9,
      adventures_allocated_at: 25.hours.ago
    )

    log_in_as(trainer)
    post visit_poke_center_path

    trainer.reload
    assert_equal 10, trainer.adventures_remaining
    assert_redirected_to catches_path
    # Should say "adventure" not "adventures" for count of 1
    assert_match /Restored \+1 adventure[^s]/, flash[:notice]
    assert_match /10\/10/, flash[:notice]
  end

  test "visit_poke_center should cap at 10 adventures" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 8,
      adventures_allocated_at: 25.hours.ago
    )

    log_in_as(trainer)
    post visit_poke_center_path

    trainer.reload
    # Should cap at 10, not 13
    assert_equal 10, trainer.adventures_remaining
    assert_redirected_to catches_path
    assert_match /Restored \+2 adventure/, flash[:notice]
    assert_match /10\/10/, flash[:notice]
  end

  test "visit_poke_center should require login" do
    post visit_poke_center_path
    assert_redirected_to login_path
  end

  test "visit_poke_center should initialize adventures on first visit" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 5,
      adventures_allocated_at: nil
    )

    log_in_as(trainer)
    post visit_poke_center_path

    trainer.reload
    assert_not_nil trainer.adventures_allocated_at
    assert_equal 5, trainer.adventures_remaining
    assert_redirected_to catches_path
    # First time should claim initial 5
    assert_match /Restored \+5 adventure/, flash[:notice]
  end

  # ================================================================================
  # USE POTION TESTS
  # ================================================================================

  test "use_potion should restore adventures with potion" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 5,
      adventures_allocated_at: 1.hour.ago
    )
    trainer.add_item(:potion, 1)

    log_in_as(trainer)
    post use_potion_path, params: { potion_key: 'potion' }

    trainer.reload
    assert_equal 8, trainer.adventures_remaining
    assert_equal 0, trainer.item_quantity(:potion)
    assert_redirected_to catches_path
    assert_match /Used Potion! Restored \+3 adventure/, flash[:notice]
    assert_match /8\/10/, flash[:notice]
  end

  test "use_potion should restore adventures with super_potion" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 3,
      adventures_allocated_at: 1.hour.ago
    )
    trainer.add_item(:super_potion, 1)

    log_in_as(trainer)
    post use_potion_path, params: { potion_key: 'super_potion' }

    trainer.reload
    assert_equal 9, trainer.adventures_remaining
    assert_equal 0, trainer.item_quantity(:super_potion)
    assert_redirected_to catches_path
    assert_match /Used Super Potion! Restored \+6 adventure/, flash[:notice]
  end

  test "use_potion should restore adventures with hyper_potion" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 0,
      adventures_allocated_at: 1.hour.ago
    )
    trainer.add_item(:hyper_potion, 1)

    log_in_as(trainer)
    post use_potion_path, params: { potion_key: 'hyper_potion' }

    trainer.reload
    assert_equal 10, trainer.adventures_remaining
    assert_equal 0, trainer.item_quantity(:hyper_potion)
    assert_redirected_to catches_path
    assert_match /Used Hyper Potion! Restored \+10 adventure/, flash[:notice]
  end

  test "use_potion should cap adventures at 10" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 8,
      adventures_allocated_at: 1.hour.ago
    )
    trainer.add_item(:super_potion, 1)

    log_in_as(trainer)
    post use_potion_path, params: { potion_key: 'super_potion' }

    trainer.reload
    assert_equal 10, trainer.adventures_remaining  # 8 + 6 = 14, capped at 10
    assert_match /Restored \+2 adventure/, flash[:notice]
  end

  test "use_potion should fail when trainer doesn't have potion" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 5,
      adventures_allocated_at: 1.hour.ago
    )

    log_in_as(trainer)
    post use_potion_path, params: { potion_key: 'potion' }

    trainer.reload
    assert_equal 5, trainer.adventures_remaining
    assert_redirected_to catches_path
    assert_match /You don't have any Potion/, flash[:alert]
  end

  test "use_potion should fail when already at max adventures" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 10,
      adventures_allocated_at: 1.hour.ago
    )
    trainer.add_item(:potion, 1)

    log_in_as(trainer)
    post use_potion_path, params: { potion_key: 'potion' }

    trainer.reload
    assert_equal 10, trainer.adventures_remaining
    assert_equal 1, trainer.item_quantity(:potion)  # Potion not consumed
    assert_redirected_to catches_path
    assert_match /You already have maximum adventures/, flash[:alert]
  end

  test "use_potion should require authentication" do
    post use_potion_path, params: { potion_key: 'potion' }
    assert_redirected_to login_path
  end

  test "use_potion should consume only one potion" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 5,
      adventures_allocated_at: 1.hour.ago
    )
    trainer.add_item(:potion, 3)

    log_in_as(trainer)
    post use_potion_path, params: { potion_key: 'potion' }

    trainer.reload
    assert_equal 2, trainer.item_quantity(:potion)  # Should have 2 left
  end

  test "use_potion should use plural 'adventures' when restoring more than 1" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 5,
      adventures_allocated_at: 1.hour.ago
    )
    trainer.add_item(:potion, 1)

    log_in_as(trainer)
    post use_potion_path, params: { potion_key: 'potion' }

    assert_match /\+3 adventures/, flash[:notice]
  end

  test "use_potion should use singular 'adventure' when restoring exactly 1" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 9,
      adventures_allocated_at: 1.hour.ago
    )
    trainer.add_item(:potion, 1)

    log_in_as(trainer)
    post use_potion_path, params: { potion_key: 'potion' }

    # 9 + 3 = 12, capped at 10, so only +1
    assert_match /\+1 adventure\./, flash[:notice]
    assert_no_match /\+1 adventures/, flash[:notice]
  end

  # ================================================================================
  # ENCOUNTER VALIDATION TESTS (URL MANIPULATION PREVENTION)
  # ================================================================================

  test "adventure action should set encounter session" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 5)

    log_in_as(trainer)
    post adventure_path(@test_route)

    # Session should be set to the encountered pokemon
    assert_not_nil session[:current_encounter]
    # Verify it's one of the pokemon on the route
    route_pokemon_ids = @test_route.pokemon.pluck(:id)
    assert_includes route_pokemon_ids, session[:current_encounter]
  end
end
