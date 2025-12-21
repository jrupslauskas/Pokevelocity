require "test_helper"

class RouteTest < ActiveSupport::TestCase
  def setup
    @route = Route.create!(order: 100, gate_requirement: nil)
    @trainer = trainers(:ash)
  end

  # ================================================================================
  # BASIC VALIDATION TESTS
  # ================================================================================

  test "should be valid with valid attributes" do
    route = Route.new(order: 101, gate_requirement: nil)
    assert route.valid?
  end

  test "should require order" do
    route = Route.new(gate_requirement: nil)
    assert_not route.valid?
  end

  test "should require unique order" do
    Route.create!(order: 102, gate_requirement: nil)
    duplicate = Route.new(order: 102, gate_requirement: nil)
    assert_not duplicate.valid?
  end

  # ================================================================================
  # ASSOCIATION TESTS
  # ================================================================================

  test "should have many route_encounters" do
    association = Route.reflect_on_association(:route_encounters)
    assert_equal :has_many, association.macro
  end

  test "should have many pokemon through route_encounters" do
    association = Route.reflect_on_association(:pokemon)
    assert_equal :has_many, association.macro
    assert_equal :route_encounters, association.options[:through]
  end

  # ================================================================================
  # FISHING ENCOUNTER TESTS
  # ================================================================================

  test "has_fishing? should return false when no fishing encounters" do
    assert_not @route.has_fishing?
  end

  test "has_fishing? should return true when route has fishing encounters" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )
    assert @route.has_fishing?
  end

  test "has_fishing? should return true when route has any fishing encounter type" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "super_rod"
    )
    assert @route.has_fishing?
  end

  test "has_fishing? should not count grass encounters" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:pidgey),
      spawn_rate: 100,
      encounter_type: "grass"
    )
    assert_not @route.has_fishing?
  end

  test "has_fishing? should not count surf encounters" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:tentacool),
      spawn_rate: 100,
      encounter_type: "surf"
    )
    assert_not @route.has_fishing?
  end

  # ================================================================================
  # SURF ENCOUNTER TESTS
  # ================================================================================

  test "has_surfing? should return false when no surf encounters" do
    assert_not @route.has_surfing?
  end

  test "has_surfing? should return true when route has surf encounters" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:tentacool),
      spawn_rate: 100,
      encounter_type: "surf"
    )
    assert @route.has_surfing?
  end

  test "has_surfing? should not count grass encounters" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:pidgey),
      spawn_rate: 100,
      encounter_type: "grass"
    )
    assert_not @route.has_surfing?
  end

  test "has_surfing? should not count fish encounters" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )
    assert_not @route.has_surfing?
  end

  # ================================================================================
  # FISHING UNLOCK TESTS
  # ================================================================================

  test "fishing_unlocked_for? should return false when route has no fishing" do
    assert_not @route.fishing_unlocked_for?(@trainer)
  end

  test "fishing_unlocked_for? should return false when trainer doesn't have required rod" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )
    @route.update!(fishing_required_item_key: "old_rod")

    assert_not @route.fishing_unlocked_for?(@trainer)
  end

  test "fishing_unlocked_for? should return true when trainer has required rod" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )
    @route.update!(fishing_required_item_key: "old_rod")
    @trainer.add_item(:old_rod, 1)

    assert @route.fishing_unlocked_for?(@trainer)
  end

  test "fishing_unlocked_for? should return true when no fishing_required_item_key" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )
    # No route-level requirement set

    assert @route.fishing_unlocked_for?(@trainer)
  end

  # ================================================================================
  # SURFING UNLOCK TESTS
  # ================================================================================

  test "surfing_unlocked_for? should return false when route has no surfing" do
    assert_not @route.surfing_unlocked_for?(@trainer)
  end

  test "surfing_unlocked_for? should return false when trainer doesn't have HM Surf" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:tentacool),
      spawn_rate: 100,
      encounter_type: "surf"
    )
    @route.update!(surfing_required_item_key: "hm_surf")

    assert_not @route.surfing_unlocked_for?(@trainer)
  end

  test "surfing_unlocked_for? should return true when trainer has HM Surf" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:tentacool),
      spawn_rate: 100,
      encounter_type: "surf"
    )
    @route.update!(surfing_required_item_key: "hm_surf")

    # Mock having HM Surf (when it's implemented)
    Item.create!(key: "hm_surf", item_type: "key_item")
    @trainer.add_item(:hm_surf, 1)

    assert @route.surfing_unlocked_for?(@trainer)
  end

  test "surfing_unlocked_for? should return true when no surfing_required_item_key" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:tentacool),
      spawn_rate: 100,
      encounter_type: "surf"
    )
    # No route-level requirement set

    assert @route.surfing_unlocked_for?(@trainer)
  end

  # ================================================================================
  # MIXED ENCOUNTER TESTS
  # ================================================================================

  test "route can have both fishing and surfing encounters" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:tentacool),
      spawn_rate: 100,
      encounter_type: "surf"
    )

    assert @route.has_fishing?
    assert @route.has_surfing?
  end

  test "route can have grass, fishing, and surfing encounters" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:pidgey),
      spawn_rate: 100,
      encounter_type: "grass"
    )
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:tentacool),
      spawn_rate: 100,
      encounter_type: "surf"
    )

    assert @route.has_fishing?
    assert @route.has_surfing?
    assert_equal 3, @route.route_encounters.count
  end

  test "route can have multiple fishing encounters with different rods" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:tentacool),
      spawn_rate: 50,
      encounter_type: "fish",
      required_item_key: "good_rod"
    )
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:gyarados),
      spawn_rate: 30,
      encounter_type: "fish",
      required_item_key: "super_rod"
    )

    assert @route.has_fishing?
    assert_equal 3, @route.route_encounters.fish.count
  end

  # ================================================================================
  # RANDOM ENCOUNTER METHOD TESTS
  # ================================================================================

  test "random_encounter should work with fishing encounters" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )

    # Call it multiple times to test randomness
    encounters = 10.times.map { @route.random_encounter }
    assert encounters.all? { |p| p == pokemons(:magikarp) }
  end

  test "random_encounter should work with surf encounters" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:tentacool),
      spawn_rate: 100,
      encounter_type: "surf"
    )

    encounter = @route.random_encounter
    assert_equal pokemons(:tentacool), encounter
  end

  test "random_encounter should distribute across all encounter types" do
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:pidgey),
      spawn_rate: 100,
      encounter_type: "grass"
    )
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:magikarp),
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )
    RouteEncounter.create!(
      route: @route,
      pokemon: pokemons(:tentacool),
      spawn_rate: 100,
      encounter_type: "surf"
    )

    # This will select across all types - testing that it works
    encounter = @route.random_encounter
    assert_includes [pokemons(:pidgey), pokemons(:magikarp), pokemons(:tentacool)], encounter
  end
end
