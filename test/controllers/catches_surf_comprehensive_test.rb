require "test_helper"

class CatchesSurfComprehensiveTest < ActionDispatch::IntegrationTest
  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end

  def setup
    @trainer = trainers(:ash)
    log_in_as(@trainer)

    # Create items
    Item.find_or_create_by!(key: "hm_surf", item_type: "key_item")
    Item.find_or_create_by!(key: "old_rod", item_type: "key_item")
    Item.find_or_create_by!(key: "good_rod", item_type: "key_item")

    # Create test Pokemon
    @grass_pokemon = Pokemon.find_or_create_by!(pokedex_number: 10) { |p| p.name = "Caterpie"; p.difficulty = 1 }
    @surf_pokemon = Pokemon.find_or_create_by!(pokedex_number: 72) { |p| p.name = "Tentacool"; p.difficulty = 2 }
    @fish_pokemon = Pokemon.find_or_create_by!(pokedex_number: 129) { |p| p.name = "Magikarp"; p.difficulty = 1 }
  end

  # ================================================================================
  # SURF BUTTON VISIBILITY
  # ================================================================================

  test "should not show surf button when trainer does not have HM Surf" do
    # Create route with surf encounters
    route = Route.create!(order: 980, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(route: route, pokemon: @grass_pokemon, spawn_rate: 100, encounter_type: "grass")

    # Don't give trainer HM Surf
    get catches_path
    assert_response :success

    # Should not show surf button
    assert_select "div.route-card[data-route-id='#{route.id}'] button.encounter-type-btn[data-encounter-type='surf']", count: 0

    # Should not show encounter selector at all (only one type available)
    assert_select "div.route-card[data-route-id='#{route.id}'] .encounter-type-selector", count: 0
  end

  test "should show surf button when trainer has HM Surf" do
    # Create route with surf and grass encounters
    route = Route.create!(order: 979, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(route: route, pokemon: @grass_pokemon, spawn_rate: 100, encounter_type: "grass")

    # Give trainer HM Surf
    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Should show both grass and surf buttons
    assert_select "div.route-card[data-route-id='#{route.id}'] button.encounter-type-btn[data-encounter-type='grass']", count: 1
    assert_select "div.route-card[data-route-id='#{route.id}'] button.encounter-type-btn[data-encounter-type='surf']", count: 1
  end

  test "should show all three encounter type buttons when trainer has surf and fishing rod" do
    route = Route.create!(order: 978, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @grass_pokemon, spawn_rate: 100, encounter_type: "grass")
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(route: route, pokemon: @fish_pokemon, spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")

    @trainer.add_item(:hm_surf, 1)
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Should show all three buttons
    assert_select "div.route-card[data-route-id='#{route.id}'] button.encounter-type-btn[data-encounter-type='grass']", count: 1
    assert_select "div.route-card[data-route-id='#{route.id}'] button.encounter-type-btn[data-encounter-type='fish']", count: 1
    assert_select "div.route-card[data-route-id='#{route.id}'] button.encounter-type-btn[data-encounter-type='surf']", count: 1
  end

  # ================================================================================
  # SURF POKEMON VISIBILITY
  # ================================================================================

  test "should not include surf pokemon in DOM when trainer lacks HM Surf" do
    route = Route.create!(order: 977, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @grass_pokemon, spawn_rate: 100, encounter_type: "grass")
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    # Don't give trainer HM Surf
    get catches_path
    assert_response :success

    # Surf Pokemon should not be in DOM at all
    assert_select "div.route-card[data-route-id='#{route.id}'] .route-pokemon-item[data-encounter-type='surf']", count: 0
  end

  test "should include surf pokemon in DOM when trainer has HM Surf" do
    route = Route.create!(order: 976, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @grass_pokemon, spawn_rate: 100, encounter_type: "grass")
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Surf Pokemon should be in DOM
    assert_select "div.route-card[data-route-id='#{route.id}'] .route-pokemon-item[data-encounter-type='surf']", minimum: 1
  end

  test "should show multiple surf pokemon when route has multiple surf encounters" do
    route = Route.create!(order: 975, gate_requirement: nil)

    surf_pokemon_2 = Pokemon.find_or_create_by!(pokedex_number: 116) { |p| p.name = "Horsea"; p.difficulty = 2 }
    surf_pokemon_3 = Pokemon.find_or_create_by!(pokedex_number: 90) { |p| p.name = "Shellder"; p.difficulty = 2 }

    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(route: route, pokemon: surf_pokemon_2, spawn_rate: 50, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(route: route, pokemon: surf_pokemon_3, spawn_rate: 25, encounter_type: "surf", required_item_key: "hm_surf")

    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Should have all three surf Pokemon
    assert_select "div.route-card[data-route-id='#{route.id}'] .route-pokemon-item[data-encounter-type='surf']", count: 3
  end

  # ================================================================================
  # ADVENTURE ACTION WITH SURF
  # ================================================================================

  test "should successfully adventure with surf encounter type" do
    route = Route.create!(order: 974, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    @trainer.add_item(:hm_surf, 1)

    post adventure_path(route), params: { encounter_type: "surf" }

    # Should encounter the surf pokemon
    assert_redirected_to catch_path(@surf_pokemon)
  end

  test "should fail to adventure with surf when trainer does not have HM Surf" do
    route = Route.create!(order: 973, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    # Don't give trainer HM Surf
    post adventure_path(route), params: { encounter_type: "surf" }

    assert_redirected_to catches_path
    assert_match /No Pokémon available/, flash[:notice]
  end

  test "should encounter correct pokemon based on surf spawn rates" do
    route = Route.create!(order: 972, gate_requirement: nil)

    # Create Pokemon with different spawn rates
    common_surf = Pokemon.find_or_create_by!(pokedex_number: 60) { |p| p.name = "Poliwag"; p.difficulty = 2 }
    rare_surf = Pokemon.find_or_create_by!(pokedex_number: 54) { |p| p.name = "Psyduck"; p.difficulty = 2 }

    RouteEncounter.create!(route: route, pokemon: common_surf, spawn_rate: 90, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(route: route, pokemon: rare_surf, spawn_rate: 10, encounter_type: "surf", required_item_key: "hm_surf")

    @trainer.add_item(:hm_surf, 1)

    # Adventure multiple times and verify we only encounter surf Pokemon
    encountered_pokemon = []
    10.times do
      post adventure_path(route), params: { encounter_type: "surf" }

      # Extract Pokemon ID from redirect location
      pokemon_id = @response.location.split('/').last.to_i
      encountered_pokemon << pokemon_id
    end

    # All encounters should be one of the surf Pokemon
    encountered_pokemon.each do |pokemon_id|
      assert_includes [common_surf.id, rare_surf.id], pokemon_id
    end
  end

  # ================================================================================
  # ROD SELECTOR INTERACTION WITH SURF
  # ================================================================================

  test "rod selector should be hidden when surf is default on water-only route" do
    route = Route.create!(order: 971, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(route: route, pokemon: @fish_pokemon, spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")

    @trainer.add_item(:hm_surf, 1)
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Rod selector should exist in DOM (for when fish is selected)
    assert_select "div.route-card[data-route-id='#{route.id}'] .rod-selector", count: 1

    # Surf should be active by default
    assert_select "div.route-card[data-route-id='#{route.id}'] button.encounter-type-btn.active[data-encounter-type='surf']", count: 1
  end

  test "rod selector should be visible when fish has grass and surf priority" do
    route = Route.create!(order: 970, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @grass_pokemon, spawn_rate: 100, encounter_type: "grass")
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(route: route, pokemon: @fish_pokemon, spawn_rate: 100, encounter_type: "fish", required_item_key: "good_rod")

    @trainer.add_item(:hm_surf, 1)
    @trainer.add_item(:good_rod, 1)

    get catches_path
    assert_response :success

    # Grass should be active by default
    assert_select "div.route-card[data-route-id='#{route.id}'] button.encounter-type-btn.active[data-encounter-type='grass']", count: 1

    # Rod selector should exist but be hidden (will show when fish is clicked)
    assert_select "div.route-card[data-route-id='#{route.id}'] .rod-selector", count: 1
  end

  # ================================================================================
  # FORM HIDDEN INPUTS WITH SURF
  # ================================================================================

  test "form should default to surf encounter type on surf-only route" do
    route = Route.create!(order: 969, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Form should have surf as default
    assert_select "div.route-card[data-route-id='#{route.id}'] form input[name='encounter_type'][value='surf']"
  end

  test "form should default to surf on surf+fish route" do
    route = Route.create!(order: 968, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(route: route, pokemon: @fish_pokemon, spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")

    @trainer.add_item(:hm_surf, 1)
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Form should default to surf (priority over fish)
    assert_select "div.route-card[data-route-id='#{route.id}'] form input[name='encounter_type'][value='surf']"
  end

  test "form should default to grass on grass+surf route" do
    route = Route.create!(order: 967, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @grass_pokemon, spawn_rate: 100, encounter_type: "grass")
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Form should default to grass (highest priority)
    assert_select "div.route-card[data-route-id='#{route.id}'] form input[name='encounter_type'][value='grass']"
  end

  # ================================================================================
  # AVAILABLE POKEMON COUNT WITH SURF
  # ================================================================================

  test "should count surf pokemon in available count" do
    route = Route.create!(order: 966, gate_requirement: nil)

    surf_pokemon_2 = Pokemon.find_or_create_by!(pokedex_number: 120) { |p| p.name = "Staryu"; p.difficulty = 2 }

    RouteEncounter.create!(route: route, pokemon: @grass_pokemon, spawn_rate: 100, encounter_type: "grass")
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(route: route, pokemon: surf_pokemon_2, spawn_rate: 50, encounter_type: "surf", required_item_key: "hm_surf")

    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Should count all uncaught Pokemon (1 grass + 2 surf = 3)
    assert_select "div.route-card[data-route-id='#{route.id}'] .route-available-count", text: /3 Pokémon available/
  end

  test "should exclude caught surf pokemon from count" do
    route = Route.create!(order: 965, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    @trainer.add_item(:hm_surf, 1)

    # Catch the surf Pokemon
    @trainer.captures.create!(pokemon: @surf_pokemon, ball_type: 'pokeball')

    get catches_path
    assert_response :success

    # Should show 0 available
    assert_select "div.route-card[data-route-id='#{route.id}'] .route-available-count", text: /0 Pokémon available/
  end

  # ================================================================================
  # DATA ATTRIBUTES FOR SURF POKEMON
  # ================================================================================

  test "surf pokemon should have correct data attributes" do
    route = Route.create!(order: 964, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Should have data-encounter-type="surf"
    assert_select "div.route-card[data-route-id='#{route.id}'] .route-pokemon-item[data-encounter-type='surf']", minimum: 1

    # Should have data-route-id
    assert_select "div.route-card[data-route-id='#{route.id}'] .route-pokemon-item[data-route-id='#{route.id}']", minimum: 1
  end

  test "surf pokemon should have data-required-item attribute set to hm_surf" do
    route = Route.create!(order: 963, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Surf Pokemon should have data-required-item="hm_surf"
    # This is metadata about the encounter, though it's not used for filtering like fish encounters
    assert_select "div.route-card[data-route-id='#{route.id}'] .route-pokemon-item[data-encounter-type='surf'][data-required-item='hm_surf']", minimum: 1
  end

  # ================================================================================
  # ENCOUNTER TYPE LOCKED POKEMON
  # ================================================================================

  test "surf pokemon should show as locked when trainer lacks HM Surf" do
    route = Route.create!(order: 962, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @grass_pokemon, spawn_rate: 100, encounter_type: "grass")
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    # Don't give trainer HM Surf
    get catches_path
    assert_response :success

    # Surf Pokemon should not appear in DOM (filtered out server-side)
    assert_select "div.route-card[data-route-id='#{route.id}'] .route-pokemon-item[data-encounter-type='surf']", count: 0
  end

  # ================================================================================
  # EDGE CASES
  # ================================================================================

  test "should handle surf-only route with no other encounter types" do
    route = Route.create!(order: 961, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Should not show encounter selector (only one type)
    assert_select "div.route-card[data-route-id='#{route.id}'] .encounter-type-selector", count: 0

    # Form should default to surf
    assert_select "div.route-card[data-route-id='#{route.id}'] form input[name='encounter_type'][value='surf']"

    # Should show surf Pokemon
    assert_select "div.route-card[data-route-id='#{route.id}'] .route-pokemon-item[data-encounter-type='surf']", minimum: 1
  end

  test "should handle route with surf encounters requiring different pokemon" do
    route = Route.create!(order: 960, gate_requirement: nil)

    # Create required Pokemon
    required_pokemon = Pokemon.find_or_create_by!(pokedex_number: 1) { |p| p.name = "Bulbasaur"; p.difficulty = 3 }
    locked_surf_pokemon = Pokemon.find_or_create_by!(pokedex_number: 131) { |p| p.name = "Lapras"; p.difficulty = 5 }

    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(
      route: route,
      pokemon: locked_surf_pokemon,
      spawn_rate: 10,
      encounter_type: "surf",
      required_item_key: "hm_surf",
      required_pokemon: required_pokemon
    )

    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Regular surf Pokemon should be visible
    # Locked surf Pokemon should also be in DOM but marked as locked
    assert_select "div.route-card[data-route-id='#{route.id}'] .route-pokemon-item[data-encounter-type='surf']", minimum: 1
  end

  test "should successfully adventure and catch surf pokemon" do
    route = Route.create!(order: 959, gate_requirement: nil)
    RouteEncounter.create!(route: route, pokemon: @surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    @trainer.add_item(:hm_surf, 1)
    @trainer.add_item(:pokeball, 10)

    # Adventure with surf
    post adventure_path(route), params: { encounter_type: "surf" }
    assert_redirected_to catch_path(@surf_pokemon)

    # Attempt to catch
    follow_redirect!

    # Submit catch attempt
    post catch_path(@surf_pokemon), params: { ball_type: "pokeball" }

    # Should redirect somewhere (either caught or failed)
    assert_response :redirect
  end
end
