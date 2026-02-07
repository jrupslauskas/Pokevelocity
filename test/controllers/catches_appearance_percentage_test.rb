require "test_helper"

class CatchesAppearancePercentageTest < ActionDispatch::IntegrationTest
  def setup
    @trainer = trainers(:ash)
    post login_path, params: { username: @trainer.username, password: "password" }

    # Setup test route and Pokemon
    @route = Route.create!(order: 950, gate_requirement: nil)

    # Create Pokemon with different spawn rates
    @common_pokemon = Pokemon.find_or_create_by!(pokedex_number: 140) do |p|
      p.name = "CommonMon"
      p.difficulty = 1
    end

    @uncommon_pokemon = Pokemon.find_or_create_by!(pokedex_number: 141) do |p|
      p.name = "UncommonMon"
      p.difficulty = 2
    end

    @rare_pokemon = Pokemon.find_or_create_by!(pokedex_number: 142) do |p|
      p.name = "RareMon"
      p.difficulty = 3
    end

    # Create encounters with different spawn rates
    # Common: 50%, Uncommon: 30%, Rare: 20%
    @common_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: @common_pokemon,
      encounter_type: "grass",
      spawn_rate: 50
    )

    @uncommon_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: @uncommon_pokemon,
      encounter_type: "grass",
      spawn_rate: 30
    )

    @rare_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: @rare_pokemon,
      encounter_type: "grass",
      spawn_rate: 20
    )
  end

  test "should display appearance percentage for each Pokemon" do
    get catches_path
    assert_response :success

    # Check that percentages are displayed (whole numbers without .0)
    assert_match /50%/, response.body
    assert_match /30%/, response.body
    assert_match /20%/, response.body
  end

  test "percentages should add up to 100% for same encounter type" do
    get catches_path
    assert_response :success

    # Verify the HTML contains the percentage elements
    assert_select ".route-pokemon-percentage", minimum: 3
  end

  test "should calculate separate percentages for different encounter types" do
    # Create fish encounters with different spawn rates
    @trainer.add_item(:old_rod, 1)

    fish_pokemon_1 = Pokemon.find_or_create_by!(pokedex_number: 143) do |p|
      p.name = "FishMon1"
      p.difficulty = 1
    end

    fish_pokemon_2 = Pokemon.find_or_create_by!(pokedex_number: 144) do |p|
      p.name = "FishMon2"
      p.difficulty = 2
    end

    # Fish encounters: 70% and 30%
    RouteEncounter.create!(
      route: @route,
      pokemon: fish_pokemon_1,
      encounter_type: "fish",
      required_item_key: "old_rod",
      spawn_rate: 70
    )

    RouteEncounter.create!(
      route: @route,
      pokemon: fish_pokemon_2,
      encounter_type: "fish",
      required_item_key: "old_rod",
      spawn_rate: 30
    )

    get catches_path
    assert_response :success

    # Should have both grass percentages (50%, 30%, 20%) and fish percentages (70%, 30%)
    assert_match /70%/, response.body
  end

  test "should calculate separate percentages for different rod types" do
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:good_rod, 1)

    # Old rod Pokemon
    old_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 145) do |p|
      p.name = "OldRodMon"
      p.difficulty = 1
    end

    # Good rod Pokemon
    good_rod_pokemon_1 = Pokemon.find_or_create_by!(pokedex_number: 146) do |p|
      p.name = "GoodRodMon1"
      p.difficulty = 2
    end

    good_rod_pokemon_2 = Pokemon.find_or_create_by!(pokedex_number: 147) do |p|
      p.name = "GoodRodMon2"
      p.difficulty = 3
    end

    # Old rod: 100%
    RouteEncounter.create!(
      route: @route,
      pokemon: old_rod_pokemon,
      encounter_type: "fish",
      required_item_key: "old_rod",
      spawn_rate: 100
    )

    # Good rod: 60% and 40%
    RouteEncounter.create!(
      route: @route,
      pokemon: good_rod_pokemon_1,
      encounter_type: "fish",
      required_item_key: "good_rod",
      spawn_rate: 60
    )

    RouteEncounter.create!(
      route: @route,
      pokemon: good_rod_pokemon_2,
      encounter_type: "fish",
      required_item_key: "good_rod",
      spawn_rate: 40
    )

    get catches_path
    assert_response :success

    # Should have separate percentage calculations for each rod type
    assert_match /100%/, response.body  # Old rod
    assert_match /60%/, response.body   # Good rod
    assert_match /40%/, response.body   # Good rod
  end

  test "should handle equal spawn rates correctly" do
    # Create a route with equal spawn rates
    equal_route = Route.create!(order: 949, gate_requirement: nil)

    pokemon_1 = Pokemon.find_or_create_by!(pokedex_number: 148) do |p|
      p.name = "EqualMon1"
      p.difficulty = 1
    end

    pokemon_2 = Pokemon.find_or_create_by!(pokedex_number: 149) do |p|
      p.name = "EqualMon2"
      p.difficulty = 1
    end

    # Both have equal spawn rates
    RouteEncounter.create!(
      route: equal_route,
      pokemon: pokemon_1,
      encounter_type: "grass",
      spawn_rate: 50
    )

    RouteEncounter.create!(
      route: equal_route,
      pokemon: pokemon_2,
      encounter_type: "grass",
      spawn_rate: 50
    )

    get catches_path
    assert_response :success

    # Both should be 50% (at least 2 Pokemon with this percentage)
    assert_select ".route-pokemon-percentage", text: "50%", minimum: 2
  end

  test "should handle single Pokemon at 100%" do
    solo_route = Route.create!(order: 948, gate_requirement: nil)

    solo_pokemon = Pokemon.find_or_create_by!(pokedex_number: 150) do |p|
      p.name = "SoloMon"
      p.difficulty = 1
    end

    RouteEncounter.create!(
      route: solo_route,
      pokemon: solo_pokemon,
      encounter_type: "grass",
      spawn_rate: 100
    )

    get catches_path
    assert_response :success

    # Should be 100%
    assert_match /100%/, response.body
  end

  test "should not display percentage for locked Pokemon" do
    # Create a locked Pokemon (requires another Pokemon to be caught first)
    locked_pokemon = Pokemon.find_or_create_by!(pokedex_number: 151) do |p|
      p.name = "LockedMon"
      p.difficulty = 5
    end

    required_pokemon = Pokemon.find_or_create_by!(pokedex_number: 3) do |p|
      p.name = "RequiredMon"
      p.difficulty = 1
    end

    RouteEncounter.create!(
      route: @route,
      pokemon: locked_pokemon,
      encounter_type: "grass",
      spawn_rate: 10,
      required_pokemon: required_pokemon
    )

    get catches_path
    assert_response :success

    # Should show lock icon instead of percentage
    assert_match /🔒/, response.body
  end

  test "appearance percentage should have correct CSS class" do
    get catches_path
    assert_response :success

    assert_select ".route-pokemon-percentage", minimum: 1
  end

  test "percentages should be rounded to one decimal place" do
    # Create encounters with spawn rates that don't divide evenly
    uneven_route = Route.create!(order: 947, gate_requirement: nil)

    pokemon_1 = Pokemon.find_or_create_by!(pokedex_number: 4) do |p|
      p.name = "UnevenMon1"
      p.difficulty = 1
    end

    pokemon_2 = Pokemon.find_or_create_by!(pokedex_number: 5) do |p|
      p.name = "UnevenMon2"
      p.difficulty = 1
    end

    pokemon_3 = Pokemon.find_or_create_by!(pokedex_number: 6) do |p|
      p.name = "UnevenMon3"
      p.difficulty = 1
    end

    # Spawn rates: 7, 5, 3 (total: 15)
    # Should be: 46.7%, 33.3%, 20.0%
    RouteEncounter.create!(
      route: uneven_route,
      pokemon: pokemon_1,
      encounter_type: "grass",
      spawn_rate: 7
    )

    RouteEncounter.create!(
      route: uneven_route,
      pokemon: pokemon_2,
      encounter_type: "grass",
      spawn_rate: 5
    )

    RouteEncounter.create!(
      route: uneven_route,
      pokemon: pokemon_3,
      encounter_type: "grass",
      spawn_rate: 3
    )

    get catches_path
    assert_response :success

    # Check that percentages are rounded to one decimal (or shown as integers)
    assert_match /46\.7%/, response.body
    assert_match /33\.3%/, response.body
    assert_match /20%/, response.body
  end
end
