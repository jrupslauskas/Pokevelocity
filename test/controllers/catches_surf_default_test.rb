require "test_helper"

class CatchesSurfDefaultTest < ActionDispatch::IntegrationTest
  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end

  def setup
    @trainer = trainers(:ash)
    log_in_as(@trainer)

    # Create HM Surf and fishing rod items
    Item.find_or_create_by!(key: "hm_surf", item_type: "key_item")
    Item.find_or_create_by!(key: "old_rod", item_type: "key_item")
  end

  test "routes with no land encounters should default to surf when trainer has both surf and fishing rod" do
    # Create a route with only surf and fish encounters (no land)
    water_only_route = Route.create!(order: 990, gate_requirement: nil)

    # Add surf encounter
    surf_pokemon = Pokemon.find_or_create_by!(pokedex_number: 72) { |p| p.name = "Tentacool"; p.difficulty = 2 }
    RouteEncounter.create!(route: water_only_route, pokemon: surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    # Add fish encounter
    fish_pokemon = Pokemon.find_or_create_by!(pokedex_number: 129) { |p| p.name = "Magikarp"; p.difficulty = 1 }
    RouteEncounter.create!(route: water_only_route, pokemon: fish_pokemon, spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")

    # Give trainer both HM Surf and Old Rod
    @trainer.add_item(:hm_surf, 1)
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Surf button should be active by default (not fish)
    assert_select "div.route-card[data-route-id='#{water_only_route.id}'] button.encounter-type-btn.active[data-encounter-type='surf']", count: 1

    # Form should default to surf encounter type
    assert_select "div.route-card[data-route-id='#{water_only_route.id}'] form input[name='encounter_type'][value='surf']"
  end

  test "routes with land encounters should still default to grass even with surf available" do
    # Create a route with all three encounter types
    mixed_route = Route.create!(order: 989, gate_requirement: nil)

    # Add grass encounter
    grass_pokemon = Pokemon.find_or_create_by!(pokedex_number: 10) { |p| p.name = "Caterpie"; p.difficulty = 1 }
    RouteEncounter.create!(route: mixed_route, pokemon: grass_pokemon, spawn_rate: 100, encounter_type: "grass")

    # Add surf encounter
    surf_pokemon = Pokemon.find_or_create_by!(pokedex_number: 72) { |p| p.name = "Tentacool"; p.difficulty = 2 }
    RouteEncounter.create!(route: mixed_route, pokemon: surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    # Add fish encounter
    fish_pokemon = Pokemon.find_or_create_by!(pokedex_number: 129) { |p| p.name = "Magikarp"; p.difficulty = 1 }
    RouteEncounter.create!(route: mixed_route, pokemon: fish_pokemon, spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")

    # Give trainer both HM Surf and Old Rod
    @trainer.add_item(:hm_surf, 1)
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Grass button should be active by default (land takes priority)
    assert_select "div.route-card[data-route-id='#{mixed_route.id}'] button.encounter-type-btn.active[data-encounter-type='grass']", count: 1

    # Form should default to grass encounter type
    assert_select "div.route-card[data-route-id='#{mixed_route.id}'] form input[name='encounter_type'][value='grass']"
  end

  test "routes with only surf and fish should default to surf (surf priority over fish)" do
    # Create a route with only surf and fish encounters
    water_route = Route.create!(order: 988, gate_requirement: nil)

    # Add surf encounter
    surf_pokemon = Pokemon.find_or_create_by!(pokedex_number: 116) { |p| p.name = "Horsea"; p.difficulty = 2 }
    RouteEncounter.create!(route: water_route, pokemon: surf_pokemon, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")

    # Add fish encounter
    fish_pokemon = Pokemon.find_or_create_by!(pokedex_number: 60) { |p| p.name = "Poliwag"; p.difficulty = 2 }
    RouteEncounter.create!(route: water_route, pokemon: fish_pokemon, spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")

    # Give trainer both items
    @trainer.add_item(:hm_surf, 1)
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Should have both buttons
    assert_select "div.route-card[data-route-id='#{water_route.id}'] button.encounter-type-btn[data-encounter-type='surf']", count: 1
    assert_select "div.route-card[data-route-id='#{water_route.id}'] button.encounter-type-btn[data-encounter-type='fish']", count: 1

    # Surf should be active (priority over fish)
    assert_select "div.route-card[data-route-id='#{water_route.id}'] button.encounter-type-btn.active[data-encounter-type='surf']", count: 1

    # Form should default to surf
    assert_select "div.route-card[data-route-id='#{water_route.id}'] form input[name='encounter_type'][value='surf']"
  end

  test "routes with only fish should default to fish when trainer has no surf" do
    # Create a route with only fish encounters
    fish_route = Route.create!(order: 987, gate_requirement: nil)

    # Add fish encounter
    fish_pokemon = Pokemon.find_or_create_by!(pokedex_number: 98) { |p| p.name = "Krabby"; p.difficulty = 2 }
    RouteEncounter.create!(route: fish_route, pokemon: fish_pokemon, spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")

    # Give trainer only fishing rod (no surf)
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Should not have encounter selector (only one type available)
    assert_select "div.route-card[data-route-id='#{fish_route.id}'] .encounter-type-selector", count: 0

    # Form should default to fish
    assert_select "div.route-card[data-route-id='#{fish_route.id}'] form input[name='encounter_type'][value='fish']"
  end

  test "priority order should be grass then surf then fish" do
    # This test documents the priority order

    # Case 1: Grass + Surf + Fish -> Grass
    route1 = Route.create!(order: 986, gate_requirement: nil)
    RouteEncounter.create!(route: route1, pokemon: Pokemon.first, spawn_rate: 100, encounter_type: "grass")
    RouteEncounter.create!(route: route1, pokemon: Pokemon.second, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(route: route1, pokemon: Pokemon.third, spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")

    # Case 2: Surf + Fish (no grass) -> Surf
    route2 = Route.create!(order: 985, gate_requirement: nil)
    RouteEncounter.create!(route: route2, pokemon: Pokemon.fourth, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(route: route2, pokemon: Pokemon.fifth, spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")

    # Case 3: Fish only (no grass or surf) -> Fish
    route3 = Route.create!(order: 984, gate_requirement: nil)
    RouteEncounter.create!(route: route3, pokemon: Pokemon.last, spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")

    # Give trainer all items
    @trainer.add_item(:hm_surf, 1)
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Route 1: Grass should be default
    if Pokemon.count >= 3
      assert_select "div.route-card[data-route-id='#{route1.id}'] form input[name='encounter_type'][value='grass']"
    end

    # Route 2: Surf should be default
    if Pokemon.count >= 5
      assert_select "div.route-card[data-route-id='#{route2.id}'] form input[name='encounter_type'][value='surf']"
    end

    # Route 3: Fish should be default
    assert_select "div.route-card[data-route-id='#{route3.id}'] form input[name='encounter_type'][value='fish']"
  end
end
