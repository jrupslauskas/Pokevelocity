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

  test "should not allow duplicate pokemon on same route" do
    @encounter.save!
    duplicate = RouteEncounter.new(route: @route, pokemon: @pokemon, spawn_rate: 30)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:pokemon_id], "already exists on this route"
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
    gate = Gate.create!(gate_number: 2, required_difficulty_score: 10)
    @encounter.required_gate_number = 2
    description = @encounter.requirement_description
    assert_includes description, "Requires:"
    assert_includes description, "Pewter City Gym"
  end

  test "requirement_description should show both when both required" do
    gate = Gate.create!(gate_number: 2, required_difficulty_score: 10)
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.required_gate_number = 2
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
    gate = Gate.create!(gate_number: 2, required_difficulty_score: 10)
    @encounter.required_pokemon = pokemons(:bulbasaur)
    @encounter.alternative_required_pokemon = pokemons(:charmander)
    @encounter.required_gate_number = 2
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
end
