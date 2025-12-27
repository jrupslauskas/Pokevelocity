require "test_helper"

class CatchesRodSelectorTest < ActionDispatch::IntegrationTest
  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end

  def setup
    @trainer = trainers(:ash)
    log_in_as(@trainer)

    # Create a test route with multiple fish encounter types
    @fishing_route = Route.create!(order: 999, gate_requirement: nil)

    # Add grass encounters
    @grass_pokemon = Pokemon.find_or_create_by!(pokedex_number: 10) { |p| p.name = "Caterpie"; p.difficulty = 1 }
    RouteEncounter.create!(
      route: @fishing_route,
      pokemon: @grass_pokemon,
      spawn_rate: 100,
      encounter_type: "grass"
    )

    # Add old rod fish encounters
    @old_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 129) { |p| p.name = "Magikarp"; p.difficulty = 1 }
    RouteEncounter.create!(
      route: @fishing_route,
      pokemon: @old_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )

    # Add good rod fish encounters
    @good_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 60) { |p| p.name = "Poliwag"; p.difficulty = 2 }
    RouteEncounter.create!(
      route: @fishing_route,
      pokemon: @good_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "good_rod"
    )

    # Add super rod fish encounters
    @super_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 98) { |p| p.name = "Krabby"; p.difficulty = 2 }
    RouteEncounter.create!(
      route: @fishing_route,
      pokemon: @super_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "super_rod"
    )

    # Create items
    Item.find_or_create_by!(key: "old_rod", item_type: "key_item")
    Item.find_or_create_by!(key: "good_rod", item_type: "key_item")
    Item.find_or_create_by!(key: "super_rod", item_type: "key_item")
  end

  # ================================================================================
  # ROD SELECTOR VISIBILITY
  # ================================================================================

  test "should not show rod selector when trainer has no fishing rods" do
    # Don't give trainer any rods
    get catches_path
    assert_response :success

    # Should not have fish button or rod selector
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.encounter-type-btn[data-encounter-type='fish']", count: 0
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] div.rod-selector", count: 0
  end

  test "should show rod selector with only old rod button when trainer has old rod" do
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Should have fish button
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.encounter-type-btn[data-encounter-type='fish']", count: 1

    # Should have rod selector with only old rod
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] div.rod-selector", count: 1
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn[data-rod-type='old_rod']", text: /Old Rod/
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn[data-rod-type='good_rod']", count: 0
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn[data-rod-type='super_rod']", count: 0
  end

  test "should show rod selector with old and good rod buttons when trainer has good rod" do
    @trainer.add_item(:good_rod, 1)

    get catches_path
    assert_response :success

    # Should have rod selector with old and good rod
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] div.rod-selector", count: 1
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn[data-rod-type='old_rod']", text: /Old Rod/
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn[data-rod-type='good_rod']", text: /Good Rod/
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn[data-rod-type='super_rod']", count: 0
  end

  test "should show rod selector with all three rod buttons when trainer has super rod" do
    @trainer.add_item(:super_rod, 1)

    get catches_path
    assert_response :success

    # Should have rod selector with all three rods
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] div.rod-selector", count: 1
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn[data-rod-type='old_rod']", text: /Old Rod/
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn[data-rod-type='good_rod']", text: /Good Rod/
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn[data-rod-type='super_rod']", text: /Super Rod/
  end

  test "should show rod selector with multiple rods when trainer has multiple rods" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:good_rod, 1)

    get catches_path
    assert_response :success

    # Should have rod selector with old and good rod (not super)
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] div.rod-selector", count: 1
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn[data-rod-type='old_rod']", text: /Old Rod/
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn[data-rod-type='good_rod']", text: /Good Rod/
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn[data-rod-type='super_rod']", count: 0
  end

  # ================================================================================
  # DEFAULT ACTIVE ROD
  # ================================================================================

  test "should have best rod active by default when trainer has multiple rods" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:good_rod, 1)

    get catches_path
    assert_response :success

    # Good rod should be active (best rod they have)
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn.active[data-rod-type='good_rod']", count: 1
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn.active[data-rod-type='old_rod']", count: 0
  end

  test "should have super rod active when trainer has all rods" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:good_rod, 1)
    @trainer.add_item(:super_rod, 1)

    get catches_path
    assert_response :success

    # Super rod should be active (best rod)
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] button.rod-btn.active[data-rod-type='super_rod']", count: 1
  end

  # ================================================================================
  # ROD SELECTOR VISIBILITY BASED ON ENCOUNTER TYPE
  # ================================================================================

  test "should hide rod selector initially when land is active" do
    @trainer.add_item(:old_rod, 1)

    get catches_path
    assert_response :success

    # Rod selector exists in DOM but should be hidden (we'll handle this with CSS/JS)
    # Check that it has the appropriate data attributes for JavaScript to show/hide
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] div.rod-selector[data-route-id='#{@fishing_route.id}']", count: 1
  end

  # ================================================================================
  # POKEMON FILTERING BY ROD TYPE
  # ================================================================================

  test "should include fish pokemon in DOM with required item data attributes" do
    @trainer.add_item(:super_rod, 1)  # Has all rods available

    get catches_path
    assert_response :success

    # All fish Pokemon should exist in DOM with data attributes
    # (JavaScript will handle showing/hiding based on selected rod type)
    # First check if any fish Pokemon exist
    assert_select "div.route-pokemon-item[data-encounter-type='fish']", minimum: 3

    # Then check for specific rod types
    assert_select "div.route-pokemon-item[data-required-item='old_rod']", minimum: 1
    assert_select "div.route-pokemon-item[data-required-item='good_rod']", minimum: 1
    assert_select "div.route-pokemon-item[data-required-item='super_rod']", minimum: 1
  end

  # ================================================================================
  # FORM INTEGRATION
  # ================================================================================

  test "should have hidden rod_type input in form" do
    @trainer.add_item(:super_rod, 1)

    get catches_path
    assert_response :success

    # Should have hidden input for rod type defaulting to best rod
    assert_select "div.route-card[data-route-id='#{@fishing_route.id}'] form.adventure-form" do
      assert_select "input[type='hidden'][name='rod_type']", count: 1
    end
  end

  # ================================================================================
  # ADVENTURE ACTION WITH ROD TYPES
  # ================================================================================

  test "should encounter old rod pokemon when rod_type is old_rod" do
    @trainer.add_item(:old_rod, 1)

    post adventure_path(@fishing_route), params: { encounter_type: "fish", rod_type: "old_rod" }

    assert_redirected_to catch_path(@old_rod_pokemon)
  end

  test "should encounter good rod pokemon when rod_type is good_rod" do
    @trainer.add_item(:good_rod, 1)

    post adventure_path(@fishing_route), params: { encounter_type: "fish", rod_type: "good_rod" }

    # Should only encounter good rod pokemon (exclusive selection)
    assert_redirected_to catch_path(@good_rod_pokemon)
  end

  test "should encounter super rod pokemon when rod_type is super_rod" do
    @trainer.add_item(:super_rod, 1)

    post adventure_path(@fishing_route), params: { encounter_type: "fish", rod_type: "super_rod" }

    # Should only encounter super rod pokemon (exclusive selection)
    assert_redirected_to catch_path(@super_rod_pokemon)
  end

  test "should use best available rod by default when rod_type is provided" do
    @trainer.add_item(:good_rod, 1)

    # When good rod is selected, should only encounter good rod pokemon
    post adventure_path(@fishing_route), params: { encounter_type: "fish", rod_type: "good_rod" }

    assert_redirected_to catch_path(@good_rod_pokemon)
  end

  # ================================================================================
  # EDGE CASES
  # ================================================================================

  test "should not show rod selector on routes without fish encounters" do
    @trainer.add_item(:old_rod, 1)

    # Create land-only route
    land_route = Route.create!(order: 1000, gate_requirement: nil)
    RouteEncounter.create!(
      route: land_route,
      pokemon: @grass_pokemon,
      spawn_rate: 100,
      encounter_type: "grass"
    )

    get catches_path
    assert_response :success

    # Should not have fish button or rod selector for this route
    assert_select "div.route-card[data-route-id='#{land_route.id}'] button.encounter-type-btn[data-encounter-type='fish']", count: 0
    assert_select "div.route-card[data-route-id='#{land_route.id}'] div.rod-selector", count: 0
  end

  test "should return error when trying to use rod trainer doesnt have" do
    @trainer.add_item(:old_rod, 1)  # Only has old rod

    # Try to use super rod
    post adventure_path(@fishing_route), params: { encounter_type: "fish", rod_type: "super_rod" }

    assert_redirected_to catches_path
    assert_match /No Pokémon available/, flash[:notice]
  end
end
