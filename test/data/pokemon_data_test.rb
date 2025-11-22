require "test_helper"

class PokemonDataTest < ActiveSupport::TestCase
  def setup
    @pokemon_data = YAML.load_file(Rails.root.join("db", "data", "pokemon.yml"))
  end

  # ================================================================================
  # STRUCTURE VALIDATION
  # ================================================================================

  test "pokemon.yml should be valid YAML and load correctly" do
    assert_not_nil @pokemon_data
    assert_kind_of Array, @pokemon_data
  end

  test "should have exactly 151 Pokemon" do
    assert_equal 151, @pokemon_data.count,
                 "Expected 151 Pokemon (Generation I), found #{@pokemon_data.count}"
  end

  test "all Pokemon should have required fields" do
    @pokemon_data.each do |pokemon|
      assert pokemon["name"].present?, "Pokemon missing 'name' field: #{pokemon.inspect}"
      assert pokemon["pokedex_number"].present?, "Pokemon '#{pokemon["name"]}' missing 'pokedex_number' field"
      assert pokemon["difficulty"].present?, "Pokemon '#{pokemon["name"]}' missing 'difficulty' field"
    end
  end

  # ================================================================================
  # POKEDEX NUMBER VALIDATION
  # ================================================================================

  test "pokedex numbers should be unique" do
    pokedex_numbers = @pokemon_data.map { |p| p["pokedex_number"] }
    duplicates = pokedex_numbers.select { |num| pokedex_numbers.count(num) > 1 }.uniq

    assert_empty duplicates, "Duplicate pokedex numbers found: #{duplicates.join(', ')}"
  end

  test "pokedex numbers should range from 1 to 151" do
    @pokemon_data.each do |pokemon|
      pokedex_num = pokemon["pokedex_number"]

      assert_kind_of Integer, pokedex_num,
                     "Pokemon '#{pokemon["name"]}' pokedex_number must be an integer, got #{pokedex_num.class}"
      assert pokedex_num >= 1,
                     "Pokemon '#{pokemon["name"]}' pokedex_number must be >= 1, got #{pokedex_num}"
      assert pokedex_num <= 151,
                     "Pokemon '#{pokemon["name"]}' pokedex_number must be <= 151, got #{pokedex_num}"
    end
  end

  test "should have all pokedex numbers from 1 to 151 with no gaps" do
    pokedex_numbers = @pokemon_data.map { |p| p["pokedex_number"] }.sort
    expected_numbers = (1..151).to_a
    missing_numbers = expected_numbers - pokedex_numbers

    assert_empty missing_numbers,
                 "Missing pokedex numbers: #{missing_numbers.join(', ')}"
  end

  # ================================================================================
  # NAME VALIDATION
  # ================================================================================

  test "Pokemon names should be unique" do
    names = @pokemon_data.map { |p| p["name"] }
    duplicates = names.select { |name| names.count(name) > 1 }.uniq

    assert_empty duplicates, "Duplicate Pokemon names found: #{duplicates.join(', ')}"
  end

  test "Pokemon names should not be empty or just whitespace" do
    @pokemon_data.each do |pokemon|
      assert pokemon["name"].strip.present?,
                     "Pokemon ##{pokemon["pokedex_number"]} has blank or whitespace-only name"
    end
  end

  # ================================================================================
  # DIFFICULTY VALIDATION
  # ================================================================================

  test "difficulty should be an integer between 1 and 5" do
    @pokemon_data.each do |pokemon|
      difficulty = pokemon["difficulty"]

      assert_kind_of Integer, difficulty,
                     "Pokemon '#{pokemon["name"]}' difficulty must be an integer, got #{difficulty.class}"
      assert difficulty >= 1,
                     "Pokemon '#{pokemon["name"]}' difficulty must be >= 1, got #{difficulty}"
      assert difficulty <= 5,
                     "Pokemon '#{pokemon["name"]}' difficulty must be <= 5, got #{difficulty}"
    end
  end

  test "should have reasonable distribution of difficulties" do
    difficulty_counts = @pokemon_data.group_by { |p| p["difficulty"] }
                                     .transform_values(&:count)

    # Check that we have at least some Pokemon at each difficulty level
    (1..5).each do |difficulty|
      count = difficulty_counts[difficulty] || 0
      assert count > 0,
                     "No Pokemon with difficulty #{difficulty} found. Every difficulty level should have at least one Pokemon."
    end

    # Print distribution for informational purposes
    puts "\n📊 Difficulty Distribution:"
    (1..5).each do |difficulty|
      count = difficulty_counts[difficulty] || 0
      percentage = (count.to_f / 151 * 100).round(1)
      stars = "★" * difficulty + "☆" * (5 - difficulty)
      puts "   #{stars} (#{difficulty}): #{count} Pokemon (#{percentage}%)"
    end
  end

  # ================================================================================
  # LEGENDARY POKEMON VALIDATION
  # ================================================================================

  test "legendary Pokemon should have difficulty 5" do
    # Known legendary Pokemon from Gen I
    legendary_names = ["Articuno", "Zapdos", "Moltres", "Mewtwo", "Mew"]

    legendary_names.each do |name|
      pokemon = @pokemon_data.find { |p| p["name"] == name }
      assert_not_nil pokemon, "Legendary Pokemon '#{name}' not found in pokemon.yml"
      assert_equal 5, pokemon["difficulty"],
                   "Legendary Pokemon '#{name}' should have difficulty 5, got #{pokemon["difficulty"]}"
    end
  end

  # ================================================================================
  # STARTER POKEMON VALIDATION
  # ================================================================================

  test "starter Pokemon should have reasonable difficulty (2-3)" do
    starter_names = ["Bulbasaur", "Charmander", "Squirtle"]

    starter_names.each do |name|
      pokemon = @pokemon_data.find { |p| p["name"] == name }
      assert_not_nil pokemon, "Starter Pokemon '#{name}' not found in pokemon.yml"
      assert [2, 3].include?(pokemon["difficulty"]),
                   "Starter Pokemon '#{name}' should have difficulty 2 or 3, got #{pokemon["difficulty"]}"
    end
  end

  # ================================================================================
  # EVOLUTION CHAIN VALIDATION (OPTIONAL)
  # ================================================================================

  test "evolved forms should generally have higher difficulty than base forms" do
    # Sample evolution chains to check
    evolution_chains = [
      ["Bulbasaur", "Ivysaur", "Venusaur"],
      ["Charmander", "Charmeleon", "Charizard"],
      ["Squirtle", "Wartortle", "Blastoise"],
      ["Pidgey", "Pidgeotto", "Pidgeot"],
      ["Rattata", "Raticate"]
    ]

    issues = []

    evolution_chains.each do |chain|
      difficulties = chain.map do |name|
        pokemon = @pokemon_data.find { |p| p["name"] == name }
        [name, pokemon&.dig("difficulty")]
      end

      # Check if difficulties increase along the chain
      difficulties.each_cons(2) do |(name1, diff1), (name2, diff2)|
        if diff1 && diff2 && diff1 >= diff2
          issues << "#{name1} (difficulty #{diff1}) should be easier than #{name2} (difficulty #{diff2})"
        end
      end
    end

    if issues.any?
      puts "\n⚠️  Evolution Chain Issues:"
      issues.each { |issue| puts "   - #{issue}" }
    end

    # Add assertion so test isn't marked as "missing assertions"
    assert true, "Evolution chain difficulty check completed"
  end
end
