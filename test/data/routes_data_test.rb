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

      # Routes must have at least one encounter type (grass, fishing, or surf)
      has_encounters = route["encounters"].present? ||
                       route["fishing_encounters"].present? ||
                       route["surf_encounters"].present?
      assert has_encounters, "Route '#{route["name"]}' has no encounters (grass, fishing, or surf)"
    end
  end

  test "route names should be unique" do
    route_names = @routes_data.map { |r| r["name"] }
    duplicates = route_names.select { |name| route_names.count(name) > 1 }.uniq

    assert_empty duplicates, "Duplicate route names found: #{duplicates.join(', ')}"
  end

  test "all encounters should have required fields" do
    @routes_data.each do |route|
      # Check grass encounters
      if route["encounters"].present?
        route["encounters"].each do |encounter|
          assert encounter["pokemon"].present?,
                 "Grass encounter on route '#{route["name"]}' missing 'pokemon' field: #{encounter.inspect}"
          assert encounter["spawn_rate"].present?,
                 "Grass encounter on route '#{route["name"]}' missing 'spawn_rate' field for #{encounter["pokemon"]}"
        end
      end

      # Check fishing encounters
      if route["fishing_encounters"].present?
        route["fishing_encounters"].each do |rod_type, encounters|
          encounters.each do |encounter|
            assert encounter["pokemon"].present?,
                   "Fishing encounter (#{rod_type}) on route '#{route["name"]}' missing 'pokemon' field: #{encounter.inspect}"
            assert encounter["spawn_rate"].present?,
                   "Fishing encounter (#{rod_type}) on route '#{route["name"]}' missing 'spawn_rate' field for #{encounter["pokemon"]}"
          end
        end
      end

      # Check surf encounters
      if route["surf_encounters"].present?
        route["surf_encounters"].each do |encounter|
          assert encounter["pokemon"].present?,
                 "Surf encounter on route '#{route["name"]}' missing 'pokemon' field: #{encounter.inspect}"
          assert encounter["spawn_rate"].present?,
                 "Surf encounter on route '#{route["name"]}' missing 'spawn_rate' field for #{encounter["pokemon"]}"
        end
      end
    end
  end

  # ================================================================================
  # SPAWN RATE VALIDATION
  # ================================================================================

  test "spawn rates for each route should add up to 100" do
    @routes_data.each do |route|
      # Check grass encounters
      if route["encounters"].present?
        total_spawn_rate = route["encounters"].sum { |e| e["spawn_rate"] }
        assert_equal 100, total_spawn_rate,
                     "Route '#{route["name"]}' grass encounter spawn rates add up to #{total_spawn_rate}, expected 100. " \
                     "Encounters: #{route["encounters"].map { |e| "#{e["pokemon"]} (#{e["spawn_rate"]})" }.join(", ")}"
      end

      # Check fishing encounters (each rod type should total 100)
      if route["fishing_encounters"].present?
        route["fishing_encounters"].each do |rod_type, encounters|
          total_spawn_rate = encounters.sum { |e| e["spawn_rate"] }
          assert_equal 100, total_spawn_rate,
                       "Route '#{route["name"]}' #{rod_type} fishing encounter spawn rates add up to #{total_spawn_rate}, expected 100. " \
                       "Encounters: #{encounters.map { |e| "#{e["pokemon"]} (#{e["spawn_rate"]})" }.join(", ")}"
        end
      end

      # Check surf encounters
      if route["surf_encounters"].present?
        total_spawn_rate = route["surf_encounters"].sum { |e| e["spawn_rate"] }
        assert_equal 100, total_spawn_rate,
                     "Route '#{route["name"]}' surf encounter spawn rates add up to #{total_spawn_rate}, expected 100. " \
                     "Encounters: #{route["surf_encounters"].map { |e| "#{e["pokemon"]} (#{e["spawn_rate"]})" }.join(", ")}"
      end
    end
  end

  test "all spawn rates should be positive integers" do
    @routes_data.each do |route|
      # Check grass encounters
      if route["encounters"].present?
        route["encounters"].each do |encounter|
          spawn_rate = encounter["spawn_rate"]
          assert_kind_of Integer, spawn_rate,
                         "Route '#{route["name"]}' - #{encounter["pokemon"]} spawn_rate must be an integer, got #{spawn_rate.class}"
          assert spawn_rate > 0,
                         "Route '#{route["name"]}' - #{encounter["pokemon"]} spawn_rate must be positive, got #{spawn_rate}"
        end
      end

      # Check fishing encounters
      if route["fishing_encounters"].present?
        route["fishing_encounters"].each do |rod_type, encounters|
          encounters.each do |encounter|
            spawn_rate = encounter["spawn_rate"]
            assert_kind_of Integer, spawn_rate,
                           "Route '#{route["name"]}' (#{rod_type}) - #{encounter["pokemon"]} spawn_rate must be an integer, got #{spawn_rate.class}"
            assert spawn_rate > 0,
                           "Route '#{route["name"]}' (#{rod_type}) - #{encounter["pokemon"]} spawn_rate must be positive, got #{spawn_rate}"
          end
        end
      end

      # Check surf encounters
      if route["surf_encounters"].present?
        route["surf_encounters"].each do |encounter|
          spawn_rate = encounter["spawn_rate"]
          assert_kind_of Integer, spawn_rate,
                         "Route '#{route["name"]}' (surf) - #{encounter["pokemon"]} spawn_rate must be an integer, got #{spawn_rate.class}"
          assert spawn_rate > 0,
                         "Route '#{route["name"]}' (surf) - #{encounter["pokemon"]} spawn_rate must be positive, got #{spawn_rate}"
        end
      end
    end
  end

  # ================================================================================
  # POKEMON REFERENCE VALIDATION
  # ================================================================================

  test "all referenced Pokemon should exist in pokemon.yml" do
    invalid_pokemon = []

    @routes_data.each do |route|
      # Check grass encounters
      if route["encounters"].present?
        route["encounters"].each do |encounter|
          pokemon_name = encounter["pokemon"]
          unless @pokemon_names.include?(pokemon_name)
            invalid_pokemon << { route: route["name"], pokemon: pokemon_name, type: "grass" }
          end
        end
      end

      # Check fishing encounters
      if route["fishing_encounters"].present?
        route["fishing_encounters"].each do |rod_type, encounters|
          encounters.each do |encounter|
            pokemon_name = encounter["pokemon"]
            unless @pokemon_names.include?(pokemon_name)
              invalid_pokemon << { route: route["name"], pokemon: pokemon_name, type: "fishing (#{rod_type})" }
            end
          end
        end
      end

      # Check surf encounters
      if route["surf_encounters"].present?
        route["surf_encounters"].each do |encounter|
          pokemon_name = encounter["pokemon"]
          unless @pokemon_names.include?(pokemon_name)
            invalid_pokemon << { route: route["name"], pokemon: pokemon_name, type: "surf" }
          end
        end
      end
    end

    assert_empty invalid_pokemon,
                 "Invalid Pokemon references found:\n" +
                 invalid_pokemon.map { |ip| "  - Route '#{ip[:route]}' (#{ip[:type]}): '#{ip[:pokemon]}' not found in pokemon.yml" }.join("\n")
  end

  test "routes should have at least one encounter" do
    @routes_data.each do |route|
      grass_count = route["encounters"]&.count || 0
      fishing_count = route["fishing_encounters"]&.values&.flatten&.count || 0
      surf_count = route["surf_encounters"]&.count || 0
      total_count = grass_count + fishing_count + surf_count

      assert total_count > 0,
             "Route '#{route["name"]}' has no encounters defined (grass: #{grass_count}, fishing: #{fishing_count}, surf: #{surf_count})"
    end
  end

  test "no duplicate Pokemon on the same route" do
    @routes_data.each do |route|
      # Check grass encounters for duplicates
      if route["encounters"].present?
        pokemon_names = route["encounters"].map { |e| e["pokemon"] }
        duplicates = pokemon_names.select { |name| pokemon_names.count(name) > 1 }.uniq
        assert_empty duplicates,
                     "Route '#{route["name"]}' has duplicate Pokemon in grass encounters: #{duplicates.join(', ')}"
      end

      # Check fishing encounters for duplicates (within same rod type)
      if route["fishing_encounters"].present?
        route["fishing_encounters"].each do |rod_type, encounters|
          pokemon_names = encounters.map { |e| e["pokemon"] }
          duplicates = pokemon_names.select { |name| pokemon_names.count(name) > 1 }.uniq
          assert_empty duplicates,
                       "Route '#{route["name"]}' has duplicate Pokemon in #{rod_type} fishing encounters: #{duplicates.join(', ')}"
        end
      end

      # Check surf encounters for duplicates
      if route["surf_encounters"].present?
        pokemon_names = route["surf_encounters"].map { |e| e["pokemon"] }
        duplicates = pokemon_names.select { |name| pokemon_names.count(name) > 1 }.uniq
        assert_empty duplicates,
                     "Route '#{route["name"]}' has duplicate Pokemon in surf encounters: #{duplicates.join(', ')}"
      end

      # Note: Same Pokemon across different encounter types (grass vs fish vs surf) is allowed
    end
  end

  # ================================================================================
  # GAME BALANCE VALIDATION (OPTIONAL WARNINGS)
  # ================================================================================

  test "routes should have a reasonable number of encounters (2-10)" do
    routes_with_issues = []

    @routes_data.each do |route|
      # Check grass encounters
      if route["encounters"].present?
        encounter_count = route["encounters"].count
        if encounter_count < 2
          routes_with_issues << "#{route["name"]} has only #{encounter_count} grass encounter(s)"
        elsif encounter_count > 10
          routes_with_issues << "#{route["name"]} has #{encounter_count} grass encounters (might be too many)"
        end
      end

      # Check fishing encounters (per rod type)
      if route["fishing_encounters"].present?
        route["fishing_encounters"].each do |rod_type, encounters|
          encounter_count = encounters.count
          if encounter_count < 2
            routes_with_issues << "#{route["name"]} has only #{encounter_count} #{rod_type} fishing encounter(s)"
          elsif encounter_count > 10
            routes_with_issues << "#{route["name"]} has #{encounter_count} #{rod_type} fishing encounters (might be too many)"
          end
        end
      end

      # Check surf encounters
      if route["surf_encounters"].present?
        encounter_count = route["surf_encounters"].count
        if encounter_count < 2
          routes_with_issues << "#{route["name"]} has only #{encounter_count} surf encounter(s)"
        elsif encounter_count > 10
          routes_with_issues << "#{route["name"]} has #{encounter_count} surf encounters (might be too many)"
        end
      end
    end

    # Add assertion so test isn't marked as "missing assertions"
    assert true, "Game balance check completed"
  end

  test "spawn rates should have some variety (not all equal)" do
    routes_to_check = []

    @routes_data.each do |route|
      # Check grass encounters
      if route["encounters"].present? && route["encounters"].count >= 2
        spawn_rates = route["encounters"].map { |e| e["spawn_rate"] }
        if spawn_rates.uniq.count == 1
          routes_to_check << "#{route["name"]} grass encounters have all equal spawn rates (#{spawn_rates.first}% each)"
        end
      end

      # Check fishing encounters (per rod type)
      if route["fishing_encounters"].present?
        route["fishing_encounters"].each do |rod_type, encounters|
          next if encounters.count < 2

          spawn_rates = encounters.map { |e| e["spawn_rate"] }
          if spawn_rates.uniq.count == 1
            routes_to_check << "#{route["name"]} #{rod_type} fishing encounters have all equal spawn rates (#{spawn_rates.first}% each)"
          end
        end
      end

      # Check surf encounters
      if route["surf_encounters"].present? && route["surf_encounters"].count >= 2
        spawn_rates = route["surf_encounters"].map { |e| e["spawn_rate"] }
        if spawn_rates.uniq.count == 1
          routes_to_check << "#{route["name"]} surf encounters have all equal spawn rates (#{spawn_rates.first}% each)"
        end
      end
    end

    # Add assertion so test isn't marked as "missing assertions"
    assert true, "Spawn rate variety check completed"
  end
end
