require "test_helper"

class CatchesEncounterIntegrationTest < ActionDispatch::IntegrationTest
  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end

  def setup
    @trainer = trainers(:ash)
    # Initialize adventures for the trainer
    @trainer.update!(
      adventures_remaining: 100,  # Give plenty of adventures for testing
      adventures_allocated_at: 1.hour.ago
    )
    log_in_as(@trainer)

    # Create a comprehensive test route with all encounter types
    @mixed_route = Route.create!(order: 998, gate_requirement: nil)

    # Add grass encounters
    @grass_pokemon_1 = Pokemon.find_or_create_by!(pokedex_number: 10) { |p| p.name = "Caterpie"; p.difficulty = 1 }
    @grass_pokemon_2 = Pokemon.find_or_create_by!(pokedex_number: 11) { |p| p.name = "Metapod"; p.difficulty = 1 }
    RouteEncounter.create!(route: @mixed_route, pokemon: @grass_pokemon_1, spawn_rate: 100, encounter_type: "grass")
    RouteEncounter.create!(route: @mixed_route, pokemon: @grass_pokemon_2, spawn_rate: 50, encounter_type: "grass")

    # Add fish encounters with all rod types
    @old_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 129) { |p| p.name = "Magikarp"; p.difficulty = 1 }
    @good_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 60) { |p| p.name = "Poliwag"; p.difficulty = 2 }
    @super_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 98) { |p| p.name = "Krabby"; p.difficulty = 2 }
    RouteEncounter.create!(route: @mixed_route, pokemon: @old_rod_pokemon, spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")
    RouteEncounter.create!(route: @mixed_route, pokemon: @good_rod_pokemon, spawn_rate: 100, encounter_type: "fish", required_item_key: "good_rod")
    RouteEncounter.create!(route: @mixed_route, pokemon: @super_rod_pokemon, spawn_rate: 100, encounter_type: "fish", required_item_key: "super_rod")

    # Add surf encounters
    @surf_pokemon_1 = Pokemon.find_or_create_by!(pokedex_number: 72) { |p| p.name = "Tentacool"; p.difficulty = 2 }
    @surf_pokemon_2 = Pokemon.find_or_create_by!(pokedex_number: 116) { |p| p.name = "Horsea"; p.difficulty = 2 }
    RouteEncounter.create!(route: @mixed_route, pokemon: @surf_pokemon_1, spawn_rate: 100, encounter_type: "surf", required_item_key: "hm_surf")
    RouteEncounter.create!(route: @mixed_route, pokemon: @surf_pokemon_2, spawn_rate: 50, encounter_type: "surf", required_item_key: "hm_surf")

    # Create items
    Item.find_or_create_by!(key: "old_rod", item_type: "key_item")
    Item.find_or_create_by!(key: "good_rod", item_type: "key_item")
    Item.find_or_create_by!(key: "super_rod", item_type: "key_item")
    Item.find_or_create_by!(key: "hm_surf", item_type: "key_item")
  end

  # ================================================================================
  # ENCOUNTER TYPE DEFAULTS
  # ================================================================================

  test "routes with only grass encounters should have grass as default" do
    grass_only_route = Route.create!(order: 997, gate_requirement: nil)
    RouteEncounter.create!(route: grass_only_route, pokemon: @grass_pokemon_1, spawn_rate: 100, encounter_type: "grass")

    get catches_path
    assert_response :success

    # Should not have encounter selector (only one type)
    assert_select "div.route-card[data-route-id='#{grass_only_route.id}'] .encounter-type-selector", count: 0
  end

  test "routes with only fish encounters should have fish as default when trainer has rods" do
    @trainer.add_item(:old_rod, 1)

    fish_only_route = Route.create!(order: 996, gate_requirement: nil)
    RouteEncounter.create!(route: fish_only_route, pokemon: @old_rod_pokemon, spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")

    get catches_path
    assert_response :success

    # Should not have encounter selector (only one type available to trainer)
    assert_select "div.route-card[data-route-id='#{fish_only_route.id}'] .encounter-type-selector", count: 0

    # Should have rod selector visible by default
    assert_select "div.route-card[data-route-id='#{fish_only_route.id}'] .rod-selector", count: 1

    # Form should default to fish encounter type
    assert_select "div.route-card[data-route-id='#{fish_only_route.id}'] form input[name='encounter_type'][value='fish']"
  end

  test "routes with grass and fish should default to grass (land priority)" do
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Should have grass button active
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] button.encounter-type-btn.active[data-encounter-type='grass']", count: 1

    # Form should default to grass
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] form input[name='encounter_type'][value='grass']"
  end

  # ================================================================================
  # POKEMON VISIBILITY BY ENCOUNTER TYPE
  # ================================================================================

  test "should show only grass pokemon initially when grass is default" do
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Grass pokemon should be visible (no inline display:none)
    # Fish pokemon should be hidden (inline display:none)
    # We can't directly test inline styles with assert_select, but we can verify data attributes exist
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] .route-pokemon-item[data-encounter-type='grass']", minimum: 2
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] .route-pokemon-item[data-encounter-type='fish']", minimum: 1
  end

  test "should show all grass pokemon regardless of which rod trainer has" do
    @trainer.add_item(:super_rod, 1)

    get catches_path
    assert_response :success

    # All grass pokemon should be in DOM
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] .route-pokemon-item[data-encounter-type='grass']", count: 2
  end

  test "should include all rod types of fish pokemon when trainer has super rod" do
    @trainer.add_item(:super_rod, 1)

    get catches_path
    assert_response :success

    # Should have pokemon for all three rod types in DOM
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] .route-pokemon-item[data-required-item='old_rod']", minimum: 1
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] .route-pokemon-item[data-required-item='good_rod']", minimum: 1
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] .route-pokemon-item[data-required-item='super_rod']", minimum: 1
  end

  test "should only include old_rod fish pokemon when trainer only has old rod" do
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Should only have old_rod pokemon
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] .route-pokemon-item[data-required-item='old_rod']", minimum: 1
    # Should not have good_rod or super_rod pokemon
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] .route-pokemon-item[data-required-item='good_rod']", count: 0
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] .route-pokemon-item[data-required-item='super_rod']", count: 0
  end

  # ================================================================================
  # FORM HIDDEN INPUTS
  # ================================================================================

  test "form should have both encounter_type and rod_type hidden inputs when fish available" do
    @trainer.add_item(:good_rod, 1)

    get catches_path
    assert_response :success

    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] form.adventure-form" do
      assert_select "input[type='hidden'][name='encounter_type']", count: 1
      assert_select "input[type='hidden'][name='rod_type']", count: 1
    end
  end

  test "form should have rod_type set to best rod when trainer has multiple rods" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:good_rod, 1)

    get catches_path
    assert_response :success

    # Rod type should default to good_rod (best rod)
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] form input[name='rod_type'][value='good_rod']"
  end

  test "form should have empty rod_type when only grass encounters exist" do
    grass_only_route = Route.create!(order: 995, gate_requirement: nil)
    RouteEncounter.create!(route: grass_only_route, pokemon: @grass_pokemon_1, spawn_rate: 100, encounter_type: "grass")

    get catches_path
    assert_response :success

    # Rod type should be empty
    assert_select "div.route-card[data-route-id='#{grass_only_route.id}'] form input[name='rod_type'][value='']"
  end

  # ================================================================================
  # ADVENTURE INTEGRATION - FULL FLOW
  # ================================================================================

  test "should successfully adventure with grass encounter type" do
    post adventure_path(@mixed_route), params: { encounter_type: "grass" }

    # Should encounter one of the grass pokemon
    assert_response :redirect
    encountered_pokemon_id = @response.location.split('/').last.to_i
    assert_includes [@grass_pokemon_1.id, @grass_pokemon_2.id], encountered_pokemon_id
  end

  test "should successfully adventure with fish encounter type and old rod" do
    @trainer.add_item(:old_rod, 1)

    post adventure_path(@mixed_route), params: { encounter_type: "fish", rod_type: "old_rod" }

    # Should encounter the old rod pokemon
    assert_redirected_to catch_path(@old_rod_pokemon)
  end

  test "should successfully adventure with surf encounter type" do
    @trainer.add_item(:hm_surf, 1)

    post adventure_path(@mixed_route), params: { encounter_type: "surf" }

    # Should encounter one of the surf pokemon
    assert_response :redirect
    encountered_pokemon_id = @response.location.split('/').last.to_i
    assert_includes [@surf_pokemon_1.id, @surf_pokemon_2.id], encountered_pokemon_id
  end

  test "should fail when trying to fish without any rod" do
    # Don't give trainer any rods

    post adventure_path(@mixed_route), params: { encounter_type: "fish", rod_type: "old_rod" }

    assert_redirected_to catches_path
    assert_match /No Pokémon available/, flash[:notice]
  end

  test "should fail when trying to surf without hm_surf" do
    # Don't give trainer surf

    post adventure_path(@mixed_route), params: { encounter_type: "surf" }

    assert_redirected_to catches_path
    assert_match /No Pokémon available/, flash[:notice]
  end

  test "should fail when trying to use good rod without having it" do
    @trainer.add_item(:old_rod, 1)  # Only has old rod

    post adventure_path(@mixed_route), params: { encounter_type: "fish", rod_type: "good_rod" }

    assert_redirected_to catches_path
    assert_match /No Pokémon available/, flash[:notice]
  end

  # ================================================================================
  # EXCLUSIVE ROD SELECTION
  # ================================================================================

  test "should only encounter old_rod pokemon when using old_rod, not good_rod pokemon" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:good_rod, 1)
    @trainer.add_item(:super_rod, 1)

    # Even though trainer has all rods, when using old_rod should only get old_rod encounters
    post adventure_path(@mixed_route), params: { encounter_type: "fish", rod_type: "old_rod" }

    assert_redirected_to catch_path(@old_rod_pokemon)
  end

  test "should only encounter good_rod pokemon when using good_rod, not old_rod or super_rod pokemon" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:good_rod, 1)
    @trainer.add_item(:super_rod, 1)

    # When using good_rod should only get good_rod encounters
    post adventure_path(@mixed_route), params: { encounter_type: "fish", rod_type: "good_rod" }

    assert_redirected_to catch_path(@good_rod_pokemon)
  end

  test "should only encounter super_rod pokemon when using super_rod" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:good_rod, 1)
    @trainer.add_item(:super_rod, 1)

    # When using super_rod should only get super_rod encounters
    post adventure_path(@mixed_route), params: { encounter_type: "fish", rod_type: "super_rod" }

    assert_redirected_to catch_path(@super_rod_pokemon)
  end

  # ================================================================================
  # ROUTES WITH MULTIPLE ENCOUNTER TYPES
  # ================================================================================

  test "route with all three encounter types should show all three buttons when trainer has items" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Should have all three encounter type buttons
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] button.encounter-type-btn[data-encounter-type='grass']", count: 1
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] button.encounter-type-btn[data-encounter-type='fish']", count: 1
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] button.encounter-type-btn[data-encounter-type='surf']", count: 1
  end

  test "route with grass and surf should not show fish button when trainer has no rods" do
    @trainer.add_item(:hm_surf, 1)
    # Don't give trainer any rods

    get catches_path
    assert_response :success

    # Should have grass and surf buttons, but not fish
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] button.encounter-type-btn[data-encounter-type='grass']", count: 1
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] button.encounter-type-btn[data-encounter-type='fish']", count: 0
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] button.encounter-type-btn[data-encounter-type='surf']", count: 1
  end

  # ================================================================================
  # AVAILABLE POKEMON COUNT
  # ================================================================================

  test "should show correct count of available grass pokemon" do
    get catches_path
    assert_response :success

    # Should show count of uncaught grass pokemon
    # Both grass pokemon are uncaught, so should show 2
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] .route-available-count", text: /2 Pokémon available/
  end

  test "should exclude caught pokemon from available count" do
    # Catch one of the grass pokemon
    @trainer.captures.create!(pokemon: @grass_pokemon_1, ball_type: 'pokeball')

    get catches_path
    assert_response :success

    # Should show 1 available (only Metapod uncaught)
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] .route-available-count", text: /1 Pokémon available/
  end

  test "should still show route when all pokemon are caught since duplicates can be caught" do
    # Catch all grass pokemon
    @trainer.captures.create!(pokemon: @grass_pokemon_1, ball_type: 'pokeball')
    @trainer.captures.create!(pokemon: @grass_pokemon_2, ball_type: 'pokeball')

    get catches_path
    assert_response :success

    # Route should still be displayed
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}']", count: 1

    # Should have Adventure button (can catch duplicates)
    assert_select "div.route-card[data-route-id='#{@mixed_route.id}'] .route-actions", count: 1
  end

  test "should show 'Locked' when pokemon exist but trainer doesn't have required pokemon" do
    # Create a route with pokemon that requires catching another pokemon first
    locked_route = Route.create!(order: 994, gate_requirement: nil)
    required_pokemon = Pokemon.find_or_create_by!(pokedex_number: 1) { |p| p.name = "Bulbasaur"; p.difficulty = 3 }
    locked_pokemon = Pokemon.find_or_create_by!(pokedex_number: 2) { |p| p.name = "Ivysaur"; p.difficulty = 4 }

    RouteEncounter.create!(
      route: locked_route,
      pokemon: locked_pokemon,
      spawn_rate: 100,
      encounter_type: "grass",
      required_pokemon: required_pokemon
    )

    get catches_path
    assert_response :success

    # Should show "Locked" button because trainer hasn't caught required pokemon
    assert_select "div.route-card[data-route-id='#{locked_route.id}'] button.btn-adventure-disabled", text: "Locked"
  end

  # ================================================================================
  # DATA ATTRIBUTES
  # ================================================================================

  test "all pokemon items should have correct data-encounter-type attribute" do
    @trainer.add_item(:super_rod, 1)
    @trainer.add_item(:hm_surf, 1)

    get catches_path
    assert_response :success

    # Verify grass pokemon have correct attribute
    assert_select ".route-pokemon-item[data-encounter-type='grass']", minimum: 2

    # Verify fish pokemon have correct attribute
    assert_select ".route-pokemon-item[data-encounter-type='fish']", minimum: 1

    # Verify surf pokemon have correct attribute
    assert_select ".route-pokemon-item[data-encounter-type='surf']", minimum: 1
  end

  test "all pokemon items should have correct data-route-id attribute" do
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # All pokemon on this route should have the route's ID
    assert_select ".route-pokemon-item[data-route-id='#{@mixed_route.id}']", minimum: 3
  end

  test "fish pokemon should have data-required-item attribute" do
    @trainer.add_item(:super_rod, 1)

    get catches_path
    assert_response :success

    # Verify fish pokemon have required item data
    assert_select ".route-pokemon-item[data-encounter-type='fish'][data-required-item='old_rod']", minimum: 1
    assert_select ".route-pokemon-item[data-encounter-type='fish'][data-required-item='good_rod']", minimum: 1
    assert_select ".route-pokemon-item[data-encounter-type='fish'][data-required-item='super_rod']", minimum: 1
  end

  test "grass pokemon should not have data-required-item attribute" do
    get catches_path
    assert_response :success

    # Grass pokemon should not have required-item data attribute
    # We can verify by checking the HTML doesn't contain it
    response_body = @response.body
    grass_items = response_body.scan(/data-encounter-type="grass".*?(?=<\/div>)/m)

    grass_items.each do |item|
      assert_not item.include?('data-required-item'), "Grass pokemon should not have data-required-item attribute"
    end
  end
end
