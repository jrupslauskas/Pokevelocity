require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  def setup
    # Clean up existing data to ensure clean test environment
    RouteEncounter.destroy_all
    Route.destroy_all
    Pokemon.destroy_all

    # Create test Pokemon
    @pidgey = Pokemon.create!(name: "Pidgey", pokedex_number: 16, difficulty: 1)
    @magikarp = Pokemon.create!(name: "Magikarp", pokedex_number: 129, difficulty: 1)
    @goldeen = Pokemon.create!(name: "Goldeen", pokedex_number: 118, difficulty: 2)
    @gyarados = Pokemon.create!(name: "Gyarados", pokedex_number: 130, difficulty: 5)
    @tentacool = Pokemon.create!(name: "Tentacool", pokedex_number: 72, difficulty: 2)
    @tentacruel = Pokemon.create!(name: "Tentacruel", pokedex_number: 73, difficulty: 4)
  end

  # ================================================================================
  # YAML STRUCTURE TESTS
  # ================================================================================

  test "routes.yml should exist and be valid YAML" do
    routes_file = Rails.root.join("db", "data", "routes.yml")
    assert File.exist?(routes_file), "routes.yml should exist"

    routes_data = YAML.load_file(routes_file)
    assert routes_data.is_a?(Array), "routes.yml should contain an array of routes"
    assert_not_empty routes_data, "routes.yml should not be empty"
  end

  test "routes_example.yml should exist and be valid YAML" do
    example_file = Rails.root.join("db", "data", "routes_example.yml")
    assert File.exist?(example_file), "routes_example.yml should exist"

    example_data = YAML.load_file(example_file)
    assert example_data.is_a?(Array), "routes_example.yml should contain an array of routes"
    assert_not_empty example_data, "routes_example.yml should not be empty"
  end

  # ================================================================================
  # GRASS ENCOUNTER CREATION
  # ================================================================================

  test "create_encounter helper creates grass encounters correctly" do
    route = Route.create!(order: 1, gate_requirement: nil)

    encounter_data = {
      "pokemon" => "Pidgey",
      "spawn_rate" => 50
    }

    # Call the helper method from seeds.rb
    encounter = create_encounter(route, encounter_data, "grass")

    assert encounter.persisted?
    assert_equal "grass", encounter.encounter_type
    assert_equal @pidgey, encounter.pokemon
    assert_equal 50, encounter.spawn_rate
    assert_nil encounter.required_item_key
  end

  test "create_encounter sets encounter_type from parameter" do
    route = Route.create!(order: 1, gate_requirement: nil)

    encounter_data = {
      "pokemon" => "Pidgey",
      "spawn_rate" => 100
    }

    # Explicitly set encounter_type
    explicit_encounter = create_encounter(route, encounter_data, "surf")

    assert_equal "surf", explicit_encounter.encounter_type
  end

  # ================================================================================
  # FISHING ENCOUNTER CREATION
  # ================================================================================

  test "create_encounter creates fishing encounters with old_rod" do
    route = Route.create!(order: 1, gate_requirement: nil)

    encounter_data = {
      "pokemon" => "Magikarp",
      "spawn_rate" => 100
    }

    encounter = create_encounter(route, encounter_data, "fish", "old_rod")

    assert encounter.persisted?
    assert_equal "fish", encounter.encounter_type
    assert_equal @magikarp, encounter.pokemon
    assert_equal 100, encounter.spawn_rate
    assert_equal "old_rod", encounter.required_item_key
  end

  test "create_encounter creates fishing encounters with good_rod" do
    route = Route.create!(order: 1, gate_requirement: nil)

    encounter_data = {
      "pokemon" => "Goldeen",
      "spawn_rate" => 50
    }

    encounter = create_encounter(route, encounter_data, "fish", "good_rod")

    assert encounter.persisted?
    assert_equal "fish", encounter.encounter_type
    assert_equal @goldeen, encounter.pokemon
    assert_equal 50, encounter.spawn_rate
    assert_equal "good_rod", encounter.required_item_key
  end

  test "create_encounter creates fishing encounters with super_rod" do
    route = Route.create!(order: 1, gate_requirement: nil)

    encounter_data = {
      "pokemon" => "Gyarados",
      "spawn_rate" => 30
    }

    encounter = create_encounter(route, encounter_data, "fish", "super_rod")

    assert encounter.persisted?
    assert_equal "fish", encounter.encounter_type
    assert_equal @gyarados, encounter.pokemon
    assert_equal 30, encounter.spawn_rate
    assert_equal "super_rod", encounter.required_item_key
  end

  # ================================================================================
  # SURF ENCOUNTER CREATION
  # ================================================================================

  test "create_encounter creates surf encounters correctly" do
    route = Route.create!(order: 1, gate_requirement: nil)

    encounter_data = {
      "pokemon" => "Tentacool",
      "spawn_rate" => 60
    }

    encounter = create_encounter(route, encounter_data, "surf")

    assert encounter.persisted?
    assert_equal "surf", encounter.encounter_type
    assert_equal @tentacool, encounter.pokemon
    assert_equal 60, encounter.spawn_rate
    assert_nil encounter.required_item_key
  end

  # ================================================================================
  # MULTIPLE ENCOUNTERS PER ROUTE
  # ================================================================================

  test "route can have multiple fishing encounters for different rods" do
    route = Route.create!(order: 1, gate_requirement: nil)

    old_rod_data = { "pokemon" => "Magikarp", "spawn_rate" => 100 }
    good_rod_data = { "pokemon" => "Goldeen", "spawn_rate" => 50 }
    super_rod_data = { "pokemon" => "Gyarados", "spawn_rate" => 30 }

    old_encounter = create_encounter(route, old_rod_data, "fish", "old_rod")
    good_encounter = create_encounter(route, good_rod_data, "fish", "good_rod")
    super_encounter = create_encounter(route, super_rod_data, "fish", "super_rod")

    assert_equal 3, route.route_encounters.fish.count

    # Verify each rod type is distinct
    old_rod_encounters = route.route_encounters.fish.where(required_item_key: "old_rod")
    good_rod_encounters = route.route_encounters.fish.where(required_item_key: "good_rod")
    super_rod_encounters = route.route_encounters.fish.where(required_item_key: "super_rod")

    assert_equal 1, old_rod_encounters.count
    assert_equal 1, good_rod_encounters.count
    assert_equal 1, super_rod_encounters.count
  end

  test "route can have grass, fishing, and surf encounters" do
    route = Route.create!(order: 1, gate_requirement: nil)

    grass_data = { "pokemon" => "Pidgey", "spawn_rate" => 100 }
    fish_data = { "pokemon" => "Magikarp", "spawn_rate" => 100 }
    surf_data = { "pokemon" => "Tentacool", "spawn_rate" => 100 }

    grass_encounter = create_encounter(route, grass_data, "grass")
    fish_encounter = create_encounter(route, fish_data, "fish", "old_rod")
    surf_encounter = create_encounter(route, surf_data, "surf")

    assert_equal 3, route.route_encounters.count
    assert_equal 1, route.route_encounters.grass.count
    assert_equal 1, route.route_encounters.fish.count
    assert_equal 1, route.route_encounters.surf.count
  end

  # ================================================================================
  # REQUIRED POKEMON AND GATE HANDLING
  # ================================================================================

  test "create_encounter handles required_pokemon correctly" do
    route = Route.create!(order: 1, gate_requirement: nil)

    encounter_data = {
      "pokemon" => "Gyarados",
      "spawn_rate" => 10,
      "required_pokemon" => "Magikarp"
    }

    encounter = create_encounter(route, encounter_data, "fish", "super_rod")

    assert_equal @magikarp.id, encounter.required_pokemon_id
  end

  test "create_encounter handles alternative_required_pokemon correctly" do
    route = Route.create!(order: 1, gate_requirement: nil)

    # Create alternative pokemon
    zapdos = Pokemon.create!(name: "Zapdos", pokedex_number: 145, difficulty: 5)

    encounter_data = {
      "pokemon" => "Gyarados",
      "spawn_rate" => 10,
      "required_pokemon" => "Magikarp",
      "alternative_required_pokemon" => "Zapdos"
    }

    encounter = create_encounter(route, encounter_data, "fish", "super_rod")

    assert_equal @magikarp.id, encounter.required_pokemon_id
    assert_equal zapdos.id, encounter.alternative_required_pokemon_id
  end

  test "create_encounter handles required_gate correctly" do
    route = Route.create!(order: 1, gate_requirement: nil)

    encounter_data = {
      "pokemon" => "Gyarados",
      "spawn_rate" => 10,
      "required_gate" => 8
    }

    encounter = create_encounter(route, encounter_data, "fish", "super_rod")

    assert_equal 8, encounter.required_gate_number
  end

  test "create_encounter clears optional fields when not present" do
    route = Route.create!(order: 1, gate_requirement: nil)

    # Create an encounter with requirements
    encounter_data_with_reqs = {
      "pokemon" => "Gyarados",
      "spawn_rate" => 10,
      "required_pokemon" => "Magikarp",
      "required_gate" => 8
    }

    encounter = create_encounter(route, encounter_data_with_reqs, "fish", "super_rod")
    assert_equal @magikarp.id, encounter.required_pokemon_id
    assert_equal 8, encounter.required_gate_number

    # Update same encounter without requirements
    encounter_data_without_reqs = {
      "pokemon" => "Gyarados",
      "spawn_rate" => 20
    }

    updated_encounter = create_encounter(route, encounter_data_without_reqs, "fish", "super_rod")

    assert_nil updated_encounter.required_pokemon_id
    assert_nil updated_encounter.alternative_required_pokemon_id
    assert_nil updated_encounter.required_gate_number
  end

  # ================================================================================
  # ERROR HANDLING
  # ================================================================================

  test "create_encounter returns nil for non-existent pokemon" do
    route = Route.create!(order: 1, gate_requirement: nil)

    encounter_data = {
      "pokemon" => "NonExistentPokemon",
      "spawn_rate" => 100
    }

    # Suppress expected warning for this test
    original_stdout = $stdout
    $stdout = StringIO.new

    encounter = create_encounter(route, encounter_data, "grass")

    $stdout = original_stdout

    assert_nil encounter
  end

  test "create_encounter handles non-existent required_pokemon" do
    route = Route.create!(order: 1, gate_requirement: nil)

    encounter_data = {
      "pokemon" => "Gyarados",
      "spawn_rate" => 10,
      "required_pokemon" => "NonExistentPokemon"
    }

    # Suppress expected warning for this test
    original_stdout = $stdout
    $stdout = StringIO.new

    encounter = create_encounter(route, encounter_data, "fish", "super_rod")

    $stdout = original_stdout

    # Encounter should still be created, but without the required_pokemon_id
    assert encounter.persisted?
    assert_nil encounter.required_pokemon_id
  end

  # ================================================================================
  # ROUTE-LEVEL REQUIREMENTS
  # ================================================================================

  test "route fishing_required_item_key can be set from YAML" do
    route = Route.create!(order: 1, gate_requirement: nil)

    # Simulate what seeds.rb does
    route.update!(fishing_required_item_key: "old_rod")

    assert_equal "old_rod", route.fishing_required_item_key
  end

  test "route surfing_required_item_key can be set from YAML" do
    route = Route.create!(order: 1, gate_requirement: nil)

    # Simulate what seeds.rb does
    route.update!(surfing_required_item_key: "hm_surf")

    assert_equal "hm_surf", route.surfing_required_item_key
  end

  # ================================================================================
  # EXAMPLE FILE VALIDATION
  # ================================================================================

  test "routes_example.yml contains all documented encounter types" do
    example_file = Rails.root.join("db", "data", "routes_example.yml")
    example_data = YAML.load_file(example_file)

    # Check that examples include fishing_encounters
    has_fishing_example = example_data.any? { |route| route["fishing_encounters"].present? }
    assert has_fishing_example, "routes_example.yml should have at least one fishing_encounters example"

    # Check that examples include surf_encounters
    has_surf_example = example_data.any? { |route| route["surf_encounters"].present? }
    assert has_surf_example, "routes_example.yml should have at least one surf_encounters example"

    # Check that examples include all rod types
    all_fishing_encounters = example_data.flat_map { |r| r["fishing_encounters"]&.keys || [] }
    assert_includes all_fishing_encounters, "old_rod", "Example should include old_rod"
    assert_includes all_fishing_encounters, "good_rod", "Example should include good_rod"
    assert_includes all_fishing_encounters, "super_rod", "Example should include super_rod"
  end

  test "routes_example.yml spawn rates total 100 per encounter group" do
    example_file = Rails.root.join("db", "data", "routes_example.yml")
    example_data = YAML.load_file(example_file)

    example_data.each_with_index do |route_data, index|
      # Check grass encounters
      if route_data["encounters"].present?
        total = route_data["encounters"].sum { |e| e["spawn_rate"] || 0 }
        assert_equal 100, total, "Route #{index} grass encounters should total 100, got #{total}"
      end

      # Check fishing encounters per rod
      if route_data["fishing_encounters"].present?
        route_data["fishing_encounters"].each do |rod_type, encounters|
          total = encounters.sum { |e| e["spawn_rate"] || 0 }
          assert_equal 100, total, "Route #{index} #{rod_type} encounters should total 100, got #{total}"
        end
      end

      # Check surf encounters
      if route_data["surf_encounters"].present?
        total = route_data["surf_encounters"].sum { |e| e["spawn_rate"] || 0 }
        assert_equal 100, total, "Route #{index} surf encounters should total 100, got #{total}"
      end
    end
  end

  # ================================================================================
  # FULL SEED SIMULATION
  # ================================================================================

  test "simulated YAML route with all encounter types creates correctly" do
    # Simulate a complete route from YAML
    route_data = {
      "order" => 99,
      "gate_requirement" => nil,
      "encounters" => [
        { "pokemon" => "Pidgey", "spawn_rate" => 100 }
      ],
      "fishing_encounters" => {
        "old_rod" => [
          { "pokemon" => "Magikarp", "spawn_rate" => 100 }
        ],
        "good_rod" => [
          { "pokemon" => "Goldeen", "spawn_rate" => 100 }
        ],
        "super_rod" => [
          { "pokemon" => "Gyarados", "spawn_rate" => 100 }
        ]
      },
      "surf_encounters" => [
        { "pokemon" => "Tentacool", "spawn_rate" => 60 },
        { "pokemon" => "Tentacruel", "spawn_rate" => 40 }
      ],
      "fishing_required_item_key" => "old_rod",
      "surfing_required_item_key" => "hm_surf"
    }

    # Create route
    route = Route.create!(order: route_data["order"], gate_requirement: route_data["gate_requirement"])

    # Create grass encounters
    route_data["encounters"].each do |encounter_data|
      create_encounter(route, encounter_data, "grass")
    end

    # Create fishing encounters
    route_data["fishing_encounters"].each do |rod_type, encounters|
      encounters.each do |encounter_data|
        create_encounter(route, encounter_data, "fish", rod_type)
      end
    end

    # Create surf encounters
    route_data["surf_encounters"].each do |encounter_data|
      create_encounter(route, encounter_data, "surf")
    end

    # Update route requirements
    route.update!(
      fishing_required_item_key: route_data["fishing_required_item_key"],
      surfing_required_item_key: route_data["surfing_required_item_key"]
    )

    # Verify everything was created
    assert_equal 1, route.route_encounters.grass.count
    assert_equal 3, route.route_encounters.fish.count
    assert_equal 2, route.route_encounters.surf.count
    assert_equal "old_rod", route.fishing_required_item_key
    assert_equal "hm_surf", route.surfing_required_item_key

    # Verify rod types are correct
    assert_equal 1, route.route_encounters.fish.where(required_item_key: "old_rod").count
    assert_equal 1, route.route_encounters.fish.where(required_item_key: "good_rod").count
    assert_equal 1, route.route_encounters.fish.where(required_item_key: "super_rod").count
  end

  private

  # Helper method from seeds.rb (copied here for testing)
  def create_encounter(route, encounter_data, encounter_type, required_item_key = nil)
    pokemon = Pokemon.find_by(name: encounter_data["pokemon"])

    if pokemon.nil?
      puts "  WARNING: Pokemon '#{encounter_data["pokemon"]}' not found, skipping encounter"
      return nil
    end

    # Find or create the encounter
    encounter = RouteEncounter.find_or_initialize_by(route: route, pokemon: pokemon, encounter_type: encounter_type, required_item_key: required_item_key)
    encounter.spawn_rate = encounter_data["spawn_rate"]

    # Handle required_pokemon
    if encounter_data["required_pokemon"].present?
      required_pokemon = Pokemon.find_by(name: encounter_data["required_pokemon"])
      if required_pokemon
        encounter.required_pokemon_id = required_pokemon.id
      else
        puts "  WARNING: Required Pokemon '#{encounter_data["required_pokemon"]}' not found for #{pokemon.name}"
      end
    else
      encounter.required_pokemon_id = nil
    end

    # Handle alternative_required_pokemon
    if encounter_data["alternative_required_pokemon"].present?
      alternative_pokemon = Pokemon.find_by(name: encounter_data["alternative_required_pokemon"])
      if alternative_pokemon
        encounter.alternative_required_pokemon_id = alternative_pokemon.id
      else
        puts "  WARNING: Alternative required Pokemon '#{encounter_data["alternative_required_pokemon"]}' not found for #{pokemon.name}"
      end
    else
      encounter.alternative_required_pokemon_id = nil
    end

    # Handle required_gate
    if encounter_data["required_gate"].present?
      encounter.required_gate_number = encounter_data["required_gate"]
    else
      encounter.required_gate_number = nil
    end

    encounter.save!
    encounter
  end
end
