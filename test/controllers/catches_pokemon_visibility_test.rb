require "test_helper"

class CatchesPokemonVisibilityTest < ActionDispatch::IntegrationTest
  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end

  def setup
    @trainer = trainers(:ash)
    log_in_as(@trainer)

    # Create a test route with multiple encounter types
    @multi_type_route = Route.create!(order: 999, gate_requirement: nil)

    # Add grass/land encounters (always accessible)
    @grass_pokemon = Pokemon.find_or_create_by!(pokedex_number: 10) { |p| p.name = "Caterpie"; p.difficulty = 1 }
    RouteEncounter.create!(
      route: @multi_type_route,
      pokemon: @grass_pokemon,
      spawn_rate: 100,
      encounter_type: "grass"
    )

    # Add old rod fish encounters
    @old_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 129) { |p| p.name = "Magikarp"; p.difficulty = 1 }
    RouteEncounter.create!(
      route: @multi_type_route,
      pokemon: @old_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )

    # Add good rod fish encounters
    @good_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 60) { |p| p.name = "Poliwag"; p.difficulty = 2 }
    RouteEncounter.create!(
      route: @multi_type_route,
      pokemon: @good_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "good_rod"
    )

    # Add super rod fish encounters
    @super_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 98) { |p| p.name = "Krabby"; p.difficulty = 2 }
    RouteEncounter.create!(
      route: @multi_type_route,
      pokemon: @super_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "super_rod"
    )

    # Add surf encounters
    @surf_pokemon = Pokemon.find_or_create_by!(pokedex_number: 72) { |p| p.name = "Tentacool"; p.difficulty = 2 }
    RouteEncounter.create!(
      route: @multi_type_route,
      pokemon: @surf_pokemon,
      spawn_rate: 100,
      encounter_type: "surf",
      required_item_key: "hm_surf"
    )

    # Create items
    Item.find_or_create_by!(key: "old_rod", item_type: "key_item")
    Item.find_or_create_by!(key: "good_rod", item_type: "key_item")
    Item.find_or_create_by!(key: "super_rod", item_type: "key_item")
    Item.find_or_create_by!(key: "hm_surf", item_type: "key_item")
  end

  # ================================================================================
  # LAND POKEMON VISIBILITY (ALWAYS VISIBLE)
  # ================================================================================

  test "should always display land encounters regardless of items" do
    # Don't give trainer any items
    get catches_path
    assert_response :success

    # Land/grass Pokemon should be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Caterpie/
    end
  end

  # ================================================================================
  # FISH POKEMON VISIBILITY (REQUIRES FISHING ROD)
  # ================================================================================

  test "should not display any fish encounters when trainer has no fishing rod" do
    # Don't give trainer any fishing rod
    get catches_path
    assert_response :success

    # Fish Pokemon should NOT be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Magikarp/, count: 0
      assert_select "div.route-pokemon-item", text: /Poliwag/, count: 0
      assert_select "div.route-pokemon-item", text: /Krabby/, count: 0
    end
  end

  test "should display old rod fish encounters when trainer has old rod" do
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Old rod Pokemon should be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Magikarp/, minimum: 1
    end

    # Better rod Pokemon should NOT be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Poliwag/, count: 0
      assert_select "div.route-pokemon-item", text: /Krabby/, count: 0
    end
  end

  test "should display old and good rod fish encounters when trainer has good rod" do
    @trainer.add_item(:good_rod, 1)

    get catches_path
    assert_response :success

    # Old and good rod Pokemon should be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Magikarp/, minimum: 1
      assert_select "div.route-pokemon-item", text: /Poliwag/, minimum: 1
    end

    # Super rod Pokemon should NOT be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Krabby/, count: 0
    end
  end

  test "should display all fish encounters when trainer has super rod" do
    @trainer.add_item(:super_rod, 1)

    get catches_path
    assert_response :success

    # All fish Pokemon should be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Magikarp/, minimum: 1
      assert_select "div.route-pokemon-item", text: /Poliwag/, minimum: 1
      assert_select "div.route-pokemon-item", text: /Krabby/, minimum: 1
    end
  end

  test "should display all fish encounters when trainer has multiple rods" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:good_rod, 1)
    @trainer.add_item(:super_rod, 1)

    get catches_path
    assert_response :success

    # All fish Pokemon should be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Magikarp/, minimum: 1
      assert_select "div.route-pokemon-item", text: /Poliwag/, minimum: 1
      assert_select "div.route-pokemon-item", text: /Krabby/, minimum: 1
    end
  end

  # ================================================================================
  # SURF POKEMON VISIBILITY (REQUIRES HM_SURF)
  # ================================================================================

  test "should not display surf encounters when trainer has no hm_surf" do
    # Don't give trainer hm_surf
    get catches_path
    assert_response :success

    # Surf Pokemon should NOT be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Tentacool/, count: 0
    end
  end

  test "should display surf encounters when trainer has hm_surf" do
    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Surf Pokemon should be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Tentacool/, minimum: 1
    end
  end

  # ================================================================================
  # COMBINED SCENARIOS
  # ================================================================================

  test "should only display land encounters when trainer has no special items" do
    # Don't give trainer any rods or surf
    get catches_path
    assert_response :success

    # Only land Pokemon should be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Caterpie/, minimum: 1
      assert_select "div.route-pokemon-item", text: /Magikarp/, count: 0
      assert_select "div.route-pokemon-item", text: /Poliwag/, count: 0
      assert_select "div.route-pokemon-item", text: /Krabby/, count: 0
      assert_select "div.route-pokemon-item", text: /Tentacool/, count: 0
    end
  end

  test "should display land and fish when trainer has fishing rod" do
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Land and old rod fish should be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Caterpie/, minimum: 1
      assert_select "div.route-pokemon-item", text: /Magikarp/, minimum: 1
    end

    # Surf should NOT be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Tentacool/, count: 0
    end
  end

  test "should display land and surf when trainer has hm_surf" do
    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Land and surf should be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Caterpie/, minimum: 1
      assert_select "div.route-pokemon-item", text: /Tentacool/, minimum: 1
    end

    # Fish should NOT be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Magikarp/, count: 0
    end
  end

  test "should display land fish and surf when trainer has all items" do
    @trainer.add_item(:super_rod, 1)
    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # All encounter types should be visible
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Caterpie/, minimum: 1
      assert_select "div.route-pokemon-item", text: /Magikarp/, minimum: 1
      assert_select "div.route-pokemon-item", text: /Poliwag/, minimum: 1
      assert_select "div.route-pokemon-item", text: /Krabby/, minimum: 1
      assert_select "div.route-pokemon-item", text: /Tentacool/, minimum: 1
    end
  end

  # ================================================================================
  # EDGE CASES
  # ================================================================================

  test "should handle route with only fish encounters when no rod" do
    fish_only_route = Route.create!(order: 1001, gate_requirement: nil)
    RouteEncounter.create!(
      route: fish_only_route,
      pokemon: @old_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )

    get catches_path
    assert_response :success

    # No Pokemon should be visible, and it should show appropriate button
    assert_select "div.route-card[data-route-id='#{fish_only_route.id}']" do
      assert_select "div.route-pokemon-item", count: 0
      assert_select "button.btn-adventure-disabled", text: "All caught!"
    end
  end

  test "should handle route with only surf encounters when no hm_surf" do
    surf_only_route = Route.create!(order: 1002, gate_requirement: nil)
    RouteEncounter.create!(
      route: surf_only_route,
      pokemon: @surf_pokemon,
      spawn_rate: 100,
      encounter_type: "surf",
      required_item_key: "hm_surf"
    )

    get catches_path
    assert_response :success

    # No Pokemon should be visible
    assert_select "div.route-card[data-route-id='#{surf_only_route.id}']" do
      assert_select "div.route-pokemon-item", count: 0
      assert_select "button.btn-adventure-disabled", text: "All caught!"
    end
  end

  test "should respect fishing rod hierarchy" do
    # Good rod should allow old rod encounters but not super rod encounters
    @trainer.add_item(:good_rod, 1)

    get catches_path
    assert_response :success

    # Should see old rod and good rod Pokemon
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}']" do
      assert_select "div.route-pokemon-item", text: /Magikarp/, minimum: 1  # old_rod
      assert_select "div.route-pokemon-item", text: /Poliwag/, minimum: 1   # good_rod
      assert_select "div.route-pokemon-item", text: /Krabby/, count: 0      # super_rod
    end
  end
end
