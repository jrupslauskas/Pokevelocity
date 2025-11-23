require "test_helper"

class RoutesDataTest < ActiveSupport::TestCase
  def setup
    @routes_data = YAML.load_file(Rails.root.join("db", "data", "routes.yml"))
    @pokemon_data = YAML.load_file(Rails.root.join("db", "data", "pokemon.yml"))
    @pokemon_names = @pokemon_data.map { |p| p["name"] }
  end

  # ================================================================================
  # STRUCTURE VALIDATION
  # ================================================================================

  test "routes.yml should be valid YAML and load correctly" do
    assert_not_nil @routes_data
    assert_kind_of Array, @routes_data
  end

  test "all routes should have required fields" do
    @routes_data.each do |route|
      assert route["name"].present?, "Route missing 'name' field: #{route.inspect}"
      assert route["description"].present?, "Route '#{route["name"]}' missing 'description' field"
      assert route["encounters"].present?, "Route '#{route["name"]}' missing 'encounters' field"
      assert_kind_of Array, route["encounters"], "Route '#{route["name"]}' encounters should be an array"
    end
  end

  test "route names should be unique" do
    route_names = @routes_data.map { |r| r["name"] }
    duplicates = route_names.select { |name| route_names.count(name) > 1 }.uniq

    assert_empty duplicates, "Duplicate route names found: #{duplicates.join(', ')}"
  end

  test "all encounters should have required fields" do
    @routes_data.each do |route|
      route["encounters"].each do |encounter|
        assert encounter["pokemon"].present?,
               "Encounter on route '#{route["name"]}' missing 'pokemon' field: #{encounter.inspect}"
        assert encounter["spawn_rate"].present?,
               "Encounter on route '#{route["name"]}' missing 'spawn_rate' field for #{encounter["pokemon"]}"
      end
    end
  end

  # ================================================================================
  # SPAWN RATE VALIDATION
  # ================================================================================

  test "spawn rates for each route should add up to 100" do
    @routes_data.each do |route|
      total_spawn_rate = route["encounters"].sum { |e| e["spawn_rate"] }

      assert_equal 100, total_spawn_rate,
                   "Route '#{route["name"]}' spawn rates add up to #{total_spawn_rate}, expected 100. " \
                   "Encounters: #{route["encounters"].map { |e| "#{e["pokemon"]} (#{e["spawn_rate"]})" }.join(", ")}"
    end
  end

  test "all spawn rates should be positive integers" do
    @routes_data.each do |route|
      route["encounters"].each do |encounter|
        spawn_rate = encounter["spawn_rate"]

        assert_kind_of Integer, spawn_rate,
                       "Route '#{route["name"]}' - #{encounter["pokemon"]} spawn_rate must be an integer, got #{spawn_rate.class}"
        assert spawn_rate > 0,
                       "Route '#{route["name"]}' - #{encounter["pokemon"]} spawn_rate must be positive, got #{spawn_rate}"
      end
    end
  end

  # ================================================================================
  # POKEMON REFERENCE VALIDATION
  # ================================================================================

  test "all referenced Pokemon should exist in pokemon.yml" do
    invalid_pokemon = []

    @routes_data.each do |route|
      route["encounters"].each do |encounter|
        pokemon_name = encounter["pokemon"]
        unless @pokemon_names.include?(pokemon_name)
          invalid_pokemon << { route: route["name"], pokemon: pokemon_name }
        end
      end
    end

    assert_empty invalid_pokemon,
                 "Invalid Pokemon references found:\n" +
                 invalid_pokemon.map { |ip| "  - Route '#{ip[:route]}': '#{ip[:pokemon]}' not found in pokemon.yml" }.join("\n")
  end

  test "routes should have at least one encounter" do
    @routes_data.each do |route|
      assert route["encounters"].any?,
                     "Route '#{route["name"]}' has no encounters defined"
    end
  end

  test "no duplicate Pokemon on the same route" do
    @routes_data.each do |route|
      pokemon_names = route["encounters"].map { |e| e["pokemon"] }
      duplicates = pokemon_names.select { |name| pokemon_names.count(name) > 1 }.uniq

      assert_empty duplicates,
                   "Route '#{route["name"]}' has duplicate Pokemon: #{duplicates.join(', ')}"
    end
  end

  # ================================================================================
  # GAME BALANCE VALIDATION (OPTIONAL WARNINGS)
  # ================================================================================

  test "routes should have a reasonable number of encounters (2-10)" do
    routes_with_issues = []

    @routes_data.each do |route|
      encounter_count = route["encounters"].count
      if encounter_count < 2
        routes_with_issues << "#{route["name"]} has only #{encounter_count} encounter(s)"
      elsif encounter_count > 10
        routes_with_issues << "#{route["name"]} has #{encounter_count} encounters (might be too many)"
      end
    end

    # This is a soft warning, not a hard failure
    if routes_with_issues.any?
      puts "\n⚠️  Game Balance Warnings:"
      routes_with_issues.each { |warning| puts "   - #{warning}" }
    end

    # Add assertion so test isn't marked as "missing assertions"
    assert true, "Game balance check completed"
  end

  test "spawn rates should have some variety (not all equal)" do
    routes_to_check = []

    @routes_data.each do |route|
      next if route["encounters"].count < 2

      spawn_rates = route["encounters"].map { |e| e["spawn_rate"] }
      if spawn_rates.uniq.count == 1
        routes_to_check << "#{route["name"]} has all equal spawn rates (#{spawn_rates.first}% each)"
      end
    end

    # This is a soft warning - equal spawn rates are valid but might not be intentional
    if routes_to_check.any?
      puts "\n💡 Consider adding variety to spawn rates:"
      routes_to_check.each { |note| puts "   - #{note}" }
    end

    # Add assertion so test isn't marked as "missing assertions"
    assert true, "Spawn rate variety check completed"
  end
end
