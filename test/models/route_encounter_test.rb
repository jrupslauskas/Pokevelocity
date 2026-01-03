require "test_helper"

class RouteEncounterTest < ActiveSupport::TestCase
  def setup
    @route = Route.create!(gate_requirement: 0, order: 100)
    @pokemon = pokemons(:pikachu)
    @encounter = RouteEncounter.new(route: @route, pokemon: @pokemon, spawn_rate: 50)
    @trainer = trainers(:ash)
  end

  # ================================================================================
  # VALIDATION TESTS
  # ================================================================================

  test "should be valid with valid attributes" do
    assert @encounter.valid?
  end

  test "should require route" do
    @encounter.route = nil
    assert_not @encounter.valid?
  end

  test "should require pokemon" do
    @encounter.pokemon = nil
    assert_not @encounter.valid?
  end

  test "should require spawn_rate" do
    @encounter.spawn_rate = nil
    assert_not @encounter.valid?
  end

  test "spawn_rate should be positive integer" do
    @encounter.spawn_rate = 0
    assert_not @encounter.valid?

    @encounter.spawn_rate = -1
    assert_not @encounter.valid?

    @encounter.spawn_rate = 1
    assert @encounter.valid?
  end

  test "should not allow duplicate pokemon on same route for same encounter type" do
    @encounter.save!
    # Same Pokemon on same route with same encounter type should fail
    duplicate = RouteEncounter.new(route: @route, pokemon: @pokemon, spawn_rate: 30, encounter_type: "grass")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:pokemon_id], "already exists on this route for this encounter type and item requirement"

    # Same Pokemon on same route with different encounter type should succeed
    different_type = RouteEncounter.new(route: @route, pokemon: @pokemon, spawn_rate: 30, encounter_type: "fish")
    assert different_type.valid?
  end

  test "required_gate_number should be between 1 and 10 if present" do
    @encounter.required_gate_number = 0
    assert_not @encounter.valid?

    @encounter.required_gate_number = 11
    assert_not @encounter.valid?

    @encounter.required_gate_number = 1
    assert @encounter.valid?

    @encounter.required_gate_number = 10
    assert @encounter.valid?

    @encounter.required_gate_number = nil
    assert @encounter.valid?
  end

  # ================================================================================
  # ASSOCIATION TESTS
  # ================================================================================

  test "should belong to route" do
    assert_respond_to @encounter, :route
    assert_instance_of Route, @encounter.route
  end

  test "should belong to pokemon" do
    assert_respond_to @encounter, :pokemon
    assert_instance_of Pokemon, @encounter.pokemon
  end

  test "should optionally belong to required_pokemon" do
    assert_respond_to @encounter, :required_pokemon
    assert_nil @encounter.required_pokemon

    @encounter.required_pokemon = pokemons(:bulbasaur)
    assert_instance_of Pokemon, @encounter.required_pokemon
  end

  # ================================================================================
  # AVAILABLE_FOR? METHOD TESTS
  # ================================================================================

  test "available_for? should return true when no requirements" do
    assert @encounter.available_for?(@trainer)
  end

  test "available_for? should return false when required pokemon not caught" do
    @encounter.required_pokemon = pokemons(:bulbasaur)
    assert_not @encounter.available_for?(@trainer)
  end

  test "available_for? should return true when required pokemon is caught" do
    @encounter.required_pokemon = pokemons(:bulbasaur)
    Capture.create!(trainer: @trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    assert @encounter.available_for?(@trainer)
  end

  test "available_for? should return false when required gate not unlocked" do
    gate = Gate.create!(gate_number: 5, required_difficulty_score: 50)
    @encounter.required_gate_number = 5
    assert_not @encounter.available_for?(@trainer)
  end

  test "available_for? should return true when required gate is unlocked" do
    gate = Gate.create!(gate_number: 5, required_difficulty_score: 50)
    @encounter.required_gate_number = 5
    GateUnlock.create!(trainer: @trainer, gate: gate, unlocked_at: Time.current)
    assert @encounter.available_for?(@trainer)
  end

  test "available_for? should require BOTH pokemon and gate when both set" do
    gate = Gate.create!(gate_number: 5, required_difficulty_score: 50)
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.required_gate_number = 5

    # Neither requirement met
    assert_not @encounter.available_for?(@trainer)

    # Only pokemon requirement met
    Capture.create!(trainer: @trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    assert_not @encounter.available_for?(@trainer)

    # Both requirements met
    GateUnlock.create!(trainer: @trainer, gate: gate, unlocked_at: Time.current)
    assert @encounter.available_for?(@trainer)
  end

  test "available_for? should work when trainer has many pokemon" do
    @encounter.required_pokemon = pokemons(:charmander)

    # Add multiple pokemon including the required one
    Capture.create!(trainer: @trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    Capture.create!(trainer: @trainer, pokemon: pokemons(:squirtle), ball_type: "pokeball")
    Capture.create!(trainer: @trainer, pokemon: pokemons(:charmander), ball_type: "pokeball")
    Capture.create!(trainer: @trainer, pokemon: pokemons(:pikachu), ball_type: "pokeball")

    assert @encounter.available_for?(@trainer)
  end

  # ================================================================================
  # OR LOGIC TESTS (ALTERNATIVE REQUIRED POKEMON)
  # ================================================================================

  test "available_for? should return false when neither required nor alternative pokemon caught" do
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.alternative_required_pokemon = pokemons(:charmander)
    assert_not @encounter.available_for?(@trainer)
  end

  test "available_for? should return true when required pokemon caught (with alternative)" do
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.alternative_required_pokemon = pokemons(:charmander)
    Capture.create!(trainer: @trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    assert @encounter.available_for?(@trainer)
  end

  test "available_for? should return true when alternative pokemon caught" do
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.alternative_required_pokemon = pokemons(:charmander)
    Capture.create!(trainer: @trainer, pokemon: pokemons(:charmander), ball_type: "pokeball")
    assert @encounter.available_for?(@trainer)
  end

  test "available_for? should return true when both required and alternative caught" do
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.alternative_required_pokemon = pokemons(:charmander)
    Capture.create!(trainer: @trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    Capture.create!(trainer: @trainer, pokemon: pokemons(:charmander), ball_type: "pokeball")
    assert @encounter.available_for?(@trainer)
  end

  test "available_for? should combine OR logic with gate requirement" do
    gate = Gate.create!(gate_number: 5, required_difficulty_score: 50)
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.alternative_required_pokemon = pokemons(:charmander)
    @encounter.required_gate_number = 5

    # Neither pokemon nor gate
    assert_not @encounter.available_for?(@trainer)

    # Only required pokemon (no gate)
    Capture.create!(trainer: @trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    assert_not @encounter.available_for?(@trainer)

    # Both pokemon and gate
    GateUnlock.create!(trainer: @trainer, gate: gate, unlocked_at: Time.current)
    assert @encounter.available_for?(@trainer)
  end

  test "available_for? should combine OR logic (alternative) with gate requirement" do
    gate = Gate.create!(gate_number: 5, required_difficulty_score: 50)
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.alternative_required_pokemon = pokemons(:charmander)
    @encounter.required_gate_number = 5

    # Only alternative pokemon (no gate)
    Capture.create!(trainer: @trainer, pokemon: pokemons(:charmander), ball_type: "pokeball")
    assert_not @encounter.available_for?(@trainer)

    # Alternative pokemon and gate
    GateUnlock.create!(trainer: @trainer, gate: gate, unlocked_at: Time.current)
    assert @encounter.available_for?(@trainer)
  end

  # ================================================================================
  # REQUIREMENT_DESCRIPTION METHOD TESTS
  # ================================================================================

  test "requirement_description should return nil when no requirements" do
    assert_nil @encounter.requirement_description
  end

  test "requirement_description should show pokemon name when only pokemon required" do
    @encounter.required_pokemon = pokemons(:bulbasaur)
    assert_equal "Requires: Bulbasaur", @encounter.requirement_description
  end

  test "requirement_description should show gate name when only gate required" do
    gate = Gate.create!(gate_number: 1, required_difficulty_score: 10)
    @encounter.required_gate_number = 1
    description = @encounter.requirement_description
    assert_includes description, "Requires:"
    assert_includes description, "Pewter City Gym"
  end

  test "requirement_description should show both when both required" do
    gate = Gate.create!(gate_number: 1, required_difficulty_score: 10)
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.required_gate_number = 1
    description = @encounter.requirement_description
    assert_includes description, "Bulbasaur"
    assert_includes description, "&"
    assert_includes description, "Pewter City Gym"
  end

  test "requirement_description should show OR when alternative pokemon exists" do
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.alternative_required_pokemon = pokemons(:charmander)
    description = @encounter.requirement_description
    assert_equal "Requires: Bulbasaur or Charmander", description
  end

  test "requirement_description should combine OR logic with gate requirement" do
    gate = Gate.create!(gate_number: 1, required_difficulty_score: 10)
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.alternative_required_pokemon = pokemons(:charmander)
    @encounter.required_gate_number = 1
    description = @encounter.requirement_description
    assert_includes description, "Bulbasaur or Charmander"
    assert_includes description, "&"
    assert_includes description, "Pewter City Gym"
  end

  # ================================================================================
  # INTEGRATION TESTS
  # ================================================================================

  test "should save encounter with pokemon requirement" do
    @encounter.required_pokemon = pokemons(:bulbasaur)
    assert @encounter.save
    assert_equal pokemons(:bulbasaur).id, @encounter.reload.required_pokemon_id
  end

  test "should save encounter with gate requirement" do
    @encounter.required_gate_number = 5
    assert @encounter.save
    assert_equal 5, @encounter.reload.required_gate_number
  end

  test "should save encounter with both requirements" do
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.required_gate_number = 5
    assert @encounter.save
    reloaded = @encounter.reload
    assert_equal pokemons(:bulbasaur).id, reloaded.required_pokemon_id
    assert_equal 5, reloaded.required_gate_number
  end

  test "should allow removing requirements" do
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.required_gate_number = 5
    @encounter.save!

    @encounter.required_pokemon_id = nil
    @encounter.required_gate_number = nil
    assert @encounter.save
    reloaded = @encounter.reload
    assert_nil reloaded.required_pokemon_id
    assert_nil reloaded.required_gate_number
  end

  test "should save encounter with alternative required pokemon" do
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.alternative_required_pokemon = pokemons(:charmander)
    assert @encounter.save
    reloaded = @encounter.reload
    assert_equal pokemons(:bulbasaur).id, reloaded.required_pokemon_id
    assert_equal pokemons(:charmander).id, reloaded.alternative_required_pokemon_id
  end

  test "should save encounter with all three requirements" do
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.alternative_required_pokemon = pokemons(:charmander)
    @encounter.required_gate_number = 5
    assert @encounter.save
    reloaded = @encounter.reload
    assert_equal pokemons(:bulbasaur).id, reloaded.required_pokemon_id
    assert_equal pokemons(:charmander).id, reloaded.alternative_required_pokemon_id
    assert_equal 5, reloaded.required_gate_number
  end

  # ================================================================================
  # ENCOUNTER TYPE TESTS
  # ================================================================================

  test "should default to grass encounter type" do
    encounter = RouteEncounter.new(route: @route, pokemon: @pokemon, spawn_rate: 50)
    assert_equal "grass", encounter.encounter_type
  end

  test "should allow setting encounter_type to fish" do
    encounter = RouteEncounter.new(route: @route, pokemon: @pokemon, spawn_rate: 50, encounter_type: "fish")
    assert_equal "fish", encounter.encounter_type
    assert encounter.valid?
  end

  test "should allow setting encounter_type to surf" do
    encounter = RouteEncounter.new(route: @route, pokemon: @pokemon, spawn_rate: 50, encounter_type: "surf")
    assert_equal "surf", encounter.encounter_type
    assert encounter.valid?
  end

  test "should have grass? predicate method" do
    encounter = RouteEncounter.new(route: @route, pokemon: @pokemon, spawn_rate: 50, encounter_type: "grass")
    assert encounter.grass?
    assert_not encounter.fish?
    assert_not encounter.surf?
  end

  test "should have fish? predicate method" do
    encounter = RouteEncounter.new(route: @route, pokemon: @pokemon, spawn_rate: 50, encounter_type: "fish")
    assert encounter.fish?
    assert_not encounter.grass?
    assert_not encounter.surf?
  end

  test "should have surf? predicate method" do
    encounter = RouteEncounter.new(route: @route, pokemon: @pokemon, spawn_rate: 50, encounter_type: "surf")
    assert encounter.surf?
    assert_not encounter.grass?
    assert_not encounter.fish?
  end

  test "should allow same pokemon on same route with different encounter types" do
    grass_encounter = RouteEncounter.create!(route: @route, pokemon: @pokemon, spawn_rate: 50, encounter_type: "grass")
    fish_encounter = RouteEncounter.create!(route: @route, pokemon: @pokemon, spawn_rate: 50, encounter_type: "fish")
    surf_encounter = RouteEncounter.create!(route: @route, pokemon: @pokemon, spawn_rate: 50, encounter_type: "surf")

    assert grass_encounter.persisted?
    assert fish_encounter.persisted?
    assert surf_encounter.persisted?
  end

  # ================================================================================
  # REQUIRED ITEM TESTS
  # ================================================================================

  test "available_for? should return false when required item not in inventory" do
    @encounter.required_item_key = "old_rod"
    assert_not @encounter.available_for?(@trainer)
  end

  test "available_for? should return true when trainer has required item" do
    @encounter.required_item_key = "old_rod"
    @trainer.add_item(:old_rod, 1)
    assert @encounter.available_for?(@trainer)
  end

  test "available_for? should work with good_rod requirement" do
    @encounter.required_item_key = "good_rod"
    assert_not @encounter.available_for?(@trainer)

    @trainer.add_item(:good_rod, 1)
    assert @encounter.available_for?(@trainer)
  end

  test "available_for? should work with super_rod requirement" do
    @encounter.required_item_key = "super_rod"
    assert_not @encounter.available_for?(@trainer)

    @trainer.add_item(:super_rod, 1)
    assert @encounter.available_for?(@trainer)
  end

  test "available_for? should require BOTH item and pokemon when both set" do
    @encounter.required_item_key = "old_rod"
    @encounter.required_pokemon = pokemons(:bulbasaur)

    # Neither requirement met
    assert_not @encounter.available_for?(@trainer)

    # Only item requirement met
    @trainer.add_item(:old_rod, 1)
    assert_not @encounter.available_for?(@trainer)

    # Both requirements met
    Capture.create!(trainer: @trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    assert @encounter.available_for?(@trainer)
  end

  test "available_for? should require item AND gate when both set" do
    gate = Gate.create!(gate_number: 5, required_difficulty_score: 50)
    @encounter.required_item_key = "old_rod"
    @encounter.required_gate_number = 5

    # Neither requirement met
    assert_not @encounter.available_for?(@trainer)

    # Only item requirement met
    @trainer.add_item(:old_rod, 1)
    assert_not @encounter.available_for?(@trainer)

    # Both requirements met
    GateUnlock.create!(trainer: @trainer, gate: gate, unlocked_at: Time.current)
    assert @encounter.available_for?(@trainer)
  end

  test "available_for? should require ALL requirements (item, pokemon, gate)" do
    gate = Gate.create!(gate_number: 5, required_difficulty_score: 50)
    @encounter.required_item_key = "old_rod"
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.required_gate_number = 5

    # No requirements met
    assert_not @encounter.available_for?(@trainer)

    # Only item
    @trainer.add_item(:old_rod, 1)
    assert_not @encounter.available_for?(@trainer)

    # Item + pokemon
    Capture.create!(trainer: @trainer, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    assert_not @encounter.available_for?(@trainer)

    # All three
    GateUnlock.create!(trainer: @trainer, gate: gate, unlocked_at: Time.current)
    assert @encounter.available_for?(@trainer)
  end

  test "requirement_description should show item when only item required" do
    @encounter.required_item_key = "old_rod"
    assert_equal "Requires: Old Rod", @encounter.requirement_description
  end

  test "requirement_description should combine item with pokemon requirement" do
    @encounter.required_item_key = "old_rod"
    @encounter.required_pokemon = pokemons(:bulbasaur)
    description = @encounter.requirement_description
    assert_includes description, "Bulbasaur"
    assert_includes description, "&"
    assert_includes description, "Old Rod"
  end

  test "requirement_description should combine item with gate requirement" do
    gate = Gate.create!(gate_number: 1, required_difficulty_score: 10)
    @encounter.required_item_key = "old_rod"
    @encounter.required_gate_number = 1
    description = @encounter.requirement_description
    assert_includes description, "Old Rod"
    assert_includes description, "&"
    assert_includes description, "Pewter City Gym"
  end

  test "requirement_description should show all requirements (item, pokemon, gate)" do
    gate = Gate.create!(gate_number: 1, required_difficulty_score: 10)
    @encounter.required_item_key = "old_rod"
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.required_gate_number = 1
    description = @encounter.requirement_description
    assert_includes description, "Bulbasaur"
    assert_includes description, "Old Rod"
    assert_includes description, "Pewter City Gym"
  end

  test "should allow same pokemon with different required items" do
    old_rod_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: @pokemon,
      spawn_rate: 50,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )
    good_rod_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: @pokemon,
      spawn_rate: 50,
      encounter_type: "fish",
      required_item_key: "good_rod"
    )

    assert old_rod_encounter.persisted?
    assert good_rod_encounter.persisted?
  end

  test "should not allow duplicate pokemon with same encounter_type and required_item_key" do
    RouteEncounter.create!(
      route: @route,
      pokemon: @pokemon,
      spawn_rate: 50,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )

    duplicate = RouteEncounter.new(
      route: @route,
      pokemon: @pokemon,
      spawn_rate: 30,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:pokemon_id], "already exists on this route for this encounter type and item requirement"
  end
end
