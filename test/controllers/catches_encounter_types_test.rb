require "test_helper"

class CatchesEncounterTypesTest < ActionDispatch::IntegrationTest
  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end

  def setup
    @trainer = trainers(:ash)
    log_in_as(@trainer)

    # Create a test route with multiple encounter types
    @multi_type_route = Route.create!(order: 999, gate_requirement: nil)

    # Add grass encounters
    @grass_pokemon = Pokemon.find_or_create_by!(pokedex_number: 10) { |p| p.name = "Caterpie"; p.difficulty = 1 }
    RouteEncounter.create!(
      route: @multi_type_route,
      pokemon: @grass_pokemon,
      spawn_rate: 100,
      encounter_type: "grass"
    )

    # Add fish encounters
    @fish_pokemon = Pokemon.find_or_create_by!(pokedex_number: 129) { |p| p.name = "Magikarp"; p.difficulty = 1 }
    RouteEncounter.create!(
      route: @multi_type_route,
      pokemon: @fish_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
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
    Item.find_or_create_by!(key: "hm_surf", item_type: "key_item")
  end

  # ================================================================================
  # ENCOUNTER TYPE SELECTOR DISPLAY TESTS
  # ================================================================================

  test "should not show encounter type selector when route has only grass encounters" do
    # Create route with only grass
    grass_only_route = Route.create!(order: 1000, gate_requirement: nil)
    RouteEncounter.create!(
      route: grass_only_route,
      pokemon: @grass_pokemon,
      spawn_rate: 100,
      encounter_type: "grass"
    )

    get catches_path
    assert_response :success

    # Should not have encounter type selector for this route
    assert_select "div.route-card[data-route-id='#{grass_only_route.id}'] div.encounter-type-selector", count: 0
  end

  test "should show encounter type selector when route has grass and fish with fishing rod" do
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Should have encounter type selector
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] div.encounter-type-selector", count: 1

    # Should have Land and Fish buttons
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='grass']", text: /Land/
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='fish']", text: /Fish/

    # Should NOT have Surf button (trainer doesn't have hm_surf)
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='surf']", count: 0
  end

  test "should show encounter type selector when route has grass and surf with hm_surf" do
    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Should have encounter type selector
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] div.encounter-type-selector", count: 1

    # Should have Land and Surf buttons
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='grass']", text: /Land/
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='surf']", text: /Surf/

    # Should NOT have Fish button (trainer doesn't have fishing rod)
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='fish']", count: 0
  end

  test "should show all three encounter type buttons when trainer has all items" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Should have encounter type selector with all 3 buttons
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] div.encounter-type-selector", count: 1
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='grass']", text: /Land/
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='fish']", text: /Fish/
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='surf']", text: /Surf/
  end

  test "should not show fish button when trainer has no fishing rod" do
    # Don't give trainer any fishing rod

    get catches_path
    assert_response :success

    # Should not show fish button
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='fish']", count: 0
  end

  test "should not show surf button when trainer has no hm_surf" do
    # Don't give trainer hm_surf

    get catches_path
    assert_response :success

    # Should not show surf button
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='surf']", count: 0
  end

  test "should not show encounter selector when only fish available but no fishing rod" do
    # Create route with only fish encounters
    fish_only_route = Route.create!(order: 1001, gate_requirement: nil)
    RouteEncounter.create!(
      route: fish_only_route,
      pokemon: @fish_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )

    # Don't give trainer fishing rod
    get catches_path
    assert_response :success

    # Should not show encounter selector (only 0 available types)
    assert_select "div.route-card[data-route-id='#{fish_only_route.id}'] div.encounter-type-selector", count: 0
  end

  # ================================================================================
  # ADVENTURE ACTION WITH ENCOUNTER TYPES
  # ================================================================================

  test "should encounter grass pokemon when encounter_type is grass" do
    post adventure_path(@multi_type_route), params: { encounter_type: "grass" }

    assert_redirected_to catch_path(@grass_pokemon)
  end

  test "should encounter fish pokemon when encounter_type is fish and has fishing rod" do
    @trainer.add_item(:old_rod, 1)

    post adventure_path(@multi_type_route), params: { encounter_type: "fish" }

    assert_redirected_to catch_path(@fish_pokemon)
  end

  test "should encounter surf pokemon when encounter_type is surf and has hm_surf" do
    @trainer.add_item(:hm_surf, 1)

    post adventure_path(@multi_type_route), params: { encounter_type: "surf" }

    assert_redirected_to catch_path(@surf_pokemon)
  end

  test "should default to grass when no encounter_type specified" do
    post adventure_path(@multi_type_route)

    assert_redirected_to catch_path(@grass_pokemon)
  end

  test "should return error when no pokemon available for encounter type" do
    # Try to fish without having caught any pokemon or having special requirements
    # The fish encounter requires old_rod which trainer doesn't have
    post adventure_path(@multi_type_route), params: { encounter_type: "fish" }

    assert_redirected_to catches_path
    assert_match "No Pokémon available for that encounter type on this route!", flash[:notice]
  end

  # ================================================================================
  # POKEMON FILTERING BY ENCOUNTER TYPE
  # ================================================================================

  test "should show pokemon with correct encounter type data attributes" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Check that grass pokemon has correct data attribute
    assert_select "div.route-pokemon-item[data-encounter-type='grass'][data-route-id='#{@multi_type_route.id}']", minimum: 1

    # Check that fish pokemon has correct data attribute
    assert_select "div.route-pokemon-item[data-encounter-type='fish'][data-route-id='#{@multi_type_route.id}']", minimum: 1

    # Check that surf pokemon has correct data attribute
    assert_select "div.route-pokemon-item[data-encounter-type='surf'][data-route-id='#{@multi_type_route.id}']", minimum: 1
  end

  test "should have active class on first available encounter type button" do
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Land should be active by default (first option)
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn.active[data-encounter-type='grass']", count: 1

    # Fish should not be active
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn.active[data-encounter-type='fish']", count: 0
  end

  # ================================================================================
  # ITEM POSSESSION CHECKS
  # ================================================================================

  test "should show fish button when trainer has good_rod" do
    # Create an encounter that requires good_rod
    good_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 60) { |p| p.name = "Poliwag"; p.difficulty = 2 }
    RouteEncounter.create!(
      route: @multi_type_route,
      pokemon: good_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "good_rod"
    )
    Item.find_or_create_by!(key: "good_rod", item_type: "key_item")

    @trainer.add_item(:good_rod, 1)

    get catches_path
    assert_response :success

    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='fish']", text: /Fish/
  end

  test "should show fish button when trainer has super_rod" do
    # Create an encounter that requires super_rod
    super_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 98) { |p| p.name = "Krabby"; p.difficulty = 2 }
    RouteEncounter.create!(
      route: @multi_type_route,
      pokemon: super_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "super_rod"
    )
    Item.find_or_create_by!(key: "super_rod", item_type: "key_item")

    @trainer.add_item(:super_rod, 1)

    get catches_path
    assert_response :success

    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='fish']", text: /Fish/
  end

  test "should show fish button when trainer has any fishing rod" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:good_rod, 1)
    @trainer.add_item(:super_rod, 1)

    get catches_path
    assert_response :success

    # Should only show one fish button (not three)
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] button.encounter-type-btn[data-encounter-type='fish']", count: 1
  end

  # ================================================================================
  # EDGE CASES
  # ================================================================================

  test "should handle route with only surf encounters and no hm_surf" do
    surf_only_route = Route.create!(order: 1002, gate_requirement: nil)
    RouteEncounter.create!(
      route: surf_only_route,
      pokemon: @surf_pokemon,
      spawn_rate: 100,
      encounter_type: "surf",
      required_item_key: "hm_surf"
    )

    # Don't give trainer hm_surf
    get catches_path
    assert_response :success

    # Should not show encounter selector (0 available types)
    assert_select "div.route-card[data-route-id='#{surf_only_route.id}'] div.encounter-type-selector", count: 0

    # Should show "All caught!" button since no pokemon are available
    assert_select "div.route-card[data-route-id='#{surf_only_route.id}'] button.btn-adventure-disabled", text: "All caught!"
  end

  test "should update available count based on encounter type" do
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Should show count for the active encounter type (grass by default)
    # The count should be for grass pokemon only when selector is shown
    assert_select "span.route-available-count[data-route-id='#{@multi_type_route.id}']"
  end

  # ================================================================================
  # POKEMON VISIBILITY BASED ON ENCOUNTER TYPE ACCESS
  # ================================================================================

  test "should not display fish pokemon when trainer has no fishing rod" do
    # Don't give trainer any fishing rod
    get catches_path
    assert_response :success

    # Fish pokemon should not be displayed at all (not even as locked)
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] div.route-pokemon-item", text: /Magikarp/, count: 0
  end

  test "should not display surf pokemon when trainer has no hm_surf" do
    # Don't give trainer hm_surf
    get catches_path
    assert_response :success

    # Surf pokemon should not be displayed at all (not even as locked)
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] div.route-pokemon-item", text: /Tentacool/, count: 0
  end

  test "should display fish pokemon when trainer gets fishing rod" do
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Fish pokemon should now be displayed
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] div.route-pokemon-item", text: /Magikarp/, minimum: 1
  end

  test "should display surf pokemon when trainer gets hm_surf" do
    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Surf pokemon should now be displayed
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] div.route-pokemon-item", text: /Tentacool/, minimum: 1
  end

  test "should only display grass pokemon when trainer has no special items" do
    # Don't give trainer any fishing rod or surf
    get catches_path
    assert_response :success

    # Should display grass pokemon
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] div.route-pokemon-item", text: /Caterpie/, minimum: 1

    # Should NOT display fish or surf pokemon
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] div.route-pokemon-item", text: /Magikarp/, count: 0
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] div.route-pokemon-item", text: /Tentacool/, count: 0
  end

  test "should display all three encounter type pokemon when trainer has all items" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Should display pokemon from all three encounter types
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] div.route-pokemon-item", text: /Caterpie/, minimum: 1  # grass
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] div.route-pokemon-item", text: /Magikarp/, minimum: 1  # fish
    assert_select "div.route-card[data-route-id='#{@multi_type_route.id}'] div.route-pokemon-item", text: /Tentacool/, minimum: 1  # surf
  end
end
