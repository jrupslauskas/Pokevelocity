require "test_helper"

class PokemonTest < ActiveSupport::TestCase
  # ================================================================================
  # VALID MODEL TESTS
  # ================================================================================

  test "should save valid pokemon" do
    pokemon = Pokemon.new(pokedex_number: 100, name: "Voltorb", difficulty: 2)
    assert pokemon.save
  end

  test "should load bulbasaur fixture" do
    pokemon = pokemons(:bulbasaur)
    assert pokemon.valid?
    assert_equal 1, pokemon.pokedex_number
    assert_equal "Bulbasaur", pokemon.name
    assert_equal 1, pokemon.difficulty
  end

  test "should load mewtwo fixture" do
    pokemon = pokemons(:mewtwo)
    assert pokemon.valid?
    assert_equal 150, pokemon.pokedex_number
    assert_equal "Mewtwo", pokemon.name
    assert_equal 5, pokemon.difficulty
  end

  # ================================================================================
  # POKEDEX NUMBER PRESENCE VALIDATION TESTS
  # ================================================================================

  test "should require pokedex_number to be present" do
    pokemon = Pokemon.new(pokedex_number: nil, name: "Testmon", difficulty: 3)
    assert_not pokemon.save
  end

  test "should add error when pokedex_number is nil" do
    pokemon = Pokemon.new(pokedex_number: nil, name: "Testmon", difficulty: 3)
    pokemon.save
    assert_includes pokemon.errors[:pokedex_number], "can't be blank"
  end

  # ================================================================================
  # POKEDEX NUMBER UNIQUENESS VALIDATION TESTS
  # ================================================================================

  test "should require unique pokedex_number" do
    existing_pokemon = pokemons(:pikachu)
    duplicate_pokemon = Pokemon.new(
      pokedex_number: existing_pokemon.pokedex_number,
      name: "Raichu",
      difficulty: 3
    )
    assert_not duplicate_pokemon.save
  end

  test "should add error when pokedex_number is not unique" do
    existing_pokemon = pokemons(:pikachu)
    duplicate_pokemon = Pokemon.new(
      pokedex_number: existing_pokemon.pokedex_number,
      name: "Raichu",
      difficulty: 3
    )
    duplicate_pokemon.save
    assert_includes duplicate_pokemon.errors[:pokedex_number], "has already been taken"
  end

  test "should allow same pokedex_number after deletion" do
    existing_pokemon = pokemons(:pikachu)
    pokedex_num = existing_pokemon.pokedex_number
    existing_pokemon.destroy

    new_pokemon = Pokemon.new(pokedex_number: pokedex_num, name: "Raichu", difficulty: 3)
    assert new_pokemon.save
  end

  # ================================================================================
  # POKEDEX NUMBER RANGE VALIDATION TESTS
  # ================================================================================

  test "should not allow pokedex_number less than 1" do
    pokemon = Pokemon.new(pokedex_number: 0, name: "InvalidMon", difficulty: 3)
    assert_not pokemon.save
  end

  test "should add error when pokedex_number is 0" do
    pokemon = Pokemon.new(pokedex_number: 0, name: "InvalidMon", difficulty: 3)
    pokemon.save
    assert_includes pokemon.errors[:pokedex_number], "must be greater than 0"
  end

  test "should not allow negative pokedex_number" do
    pokemon = Pokemon.new(pokedex_number: -1, name: "InvalidMon", difficulty: 3)
    assert_not pokemon.save
  end

  test "should allow pokedex_number of 1" do
    # Bulbasaur already uses 1, so destroy it first
    pokemons(:bulbasaur).destroy
    pokemon = Pokemon.new(pokedex_number: 1, name: "NewMon", difficulty: 3)
    assert pokemon.save
  end

  test "should allow pokedex_number of 151" do
    # Mew already uses 151, so destroy it first
    pokemons(:mew).destroy
    pokemon = Pokemon.new(pokedex_number: 151, name: "NewMon", difficulty: 3)
    assert pokemon.save
  end

  test "should not allow pokedex_number greater than 151" do
    pokemon = Pokemon.new(pokedex_number: 152, name: "Chikorita", difficulty: 3)
    assert_not pokemon.save
  end

  test "should add error when pokedex_number exceeds 151" do
    pokemon = Pokemon.new(pokedex_number: 200, name: "InvalidMon", difficulty: 3)
    pokemon.save
    assert_includes pokemon.errors[:pokedex_number], "must be less than or equal to 151"
  end

  # ================================================================================
  # POKEDEX NUMBER TYPE VALIDATION TESTS
  # ================================================================================

  test "should not allow decimal pokedex_number" do
    pokemon = Pokemon.new(pokedex_number: 1.5, name: "InvalidMon", difficulty: 3)
    assert_not pokemon.save
  end

  test "should add error when pokedex_number is decimal" do
    pokemon = Pokemon.new(pokedex_number: 1.5, name: "InvalidMon", difficulty: 3)
    pokemon.save
    assert_includes pokemon.errors[:pokedex_number], "must be an integer"
  end

  test "should not allow string pokedex_number" do
    pokemon = Pokemon.new(pokedex_number: "abc", name: "InvalidMon", difficulty: 3)
    assert_not pokemon.save
  end

  # ================================================================================
  # NAME PRESENCE VALIDATION TESTS
  # ================================================================================

  test "should require name to be present" do
    pokemon = Pokemon.new(pokedex_number: 50, name: nil, difficulty: 3)
    assert_not pokemon.save
  end

  test "should add error when name is nil" do
    pokemon = Pokemon.new(pokedex_number: 50, name: nil, difficulty: 3)
    pokemon.save
    assert_includes pokemon.errors[:name], "can't be blank"
  end

  test "should not save with empty name" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "", difficulty: 3)
    assert_not pokemon.save
  end

  test "should add error when name is empty" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "", difficulty: 3)
    pokemon.save
    assert_includes pokemon.errors[:name], "can't be blank"
  end

  test "should allow name with spaces" do
    pokemon = Pokemon.new(pokedex_number: 122, name: "Mr. Mime", difficulty: 3)
    assert pokemon.save
  end

  test "should allow name with special characters" do
    pokemon = Pokemon.new(pokedex_number: 29, name: "Nidoran♀", difficulty: 2)
    assert pokemon.save
  end

  # ================================================================================
  # DIFFICULTY PRESENCE VALIDATION TESTS
  # ================================================================================

  test "should require difficulty to be present" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "Testmon", difficulty: nil)
    assert_not pokemon.save
  end

  test "should add error when difficulty is nil" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "Testmon", difficulty: nil)
    pokemon.save
    assert_includes pokemon.errors[:difficulty], "can't be blank"
  end

  # ================================================================================
  # DIFFICULTY RANGE VALIDATION TESTS
  # ================================================================================

  test "should allow difficulty of 1" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "EasyMon", difficulty: 1)
    assert pokemon.save
  end

  test "should allow difficulty of 5" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "HardMon", difficulty: 5)
    assert pokemon.save
  end

  test "should not allow difficulty less than 1" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "InvalidMon", difficulty: 0)
    assert_not pokemon.save
  end

  test "should add error when difficulty is 0" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "InvalidMon", difficulty: 0)
    pokemon.save
    assert_includes pokemon.errors[:difficulty], "must be greater than or equal to 1"
  end

  test "should not allow negative difficulty" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "InvalidMon", difficulty: -1)
    assert_not pokemon.save
  end

  test "should not allow difficulty greater than 5" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "InvalidMon", difficulty: 6)
    assert_not pokemon.save
  end

  test "should add error when difficulty exceeds 5" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "InvalidMon", difficulty: 10)
    pokemon.save
    assert_includes pokemon.errors[:difficulty], "must be less than or equal to 5"
  end

  # ================================================================================
  # DIFFICULTY TYPE VALIDATION TESTS
  # ================================================================================

  test "should not allow decimal difficulty" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "InvalidMon", difficulty: 2.5)
    assert_not pokemon.save
  end

  test "should add error when difficulty is decimal" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "InvalidMon", difficulty: 3.7)
    pokemon.save
    assert_includes pokemon.errors[:difficulty], "must be an integer"
  end

  test "should not allow string difficulty" do
    pokemon = Pokemon.new(pokedex_number: 50, name: "InvalidMon", difficulty: "hard")
    assert_not pokemon.save
  end

  # ================================================================================
  # ASSOCIATION TESTS
  # ================================================================================

  test "should have many captures" do
    pokemon = pokemons(:charmander)
    assert_respond_to pokemon, :captures
  end

  test "should have many trainers through captures" do
    pokemon = pokemons(:charmander)
    assert_respond_to pokemon, :trainers
  end

  test "should return captured trainers" do
    pokemon = pokemons(:charmander)
    trainer = trainers(:gary)

    # Gary captured charmander in fixtures
    assert_includes pokemon.trainers, trainer
  end

  test "should destroy dependent captures when pokemon is destroyed" do
    pokemon = pokemons(:charmander)
    capture_count = pokemon.captures.count

    assert_difference("Capture.count", -capture_count) do
      pokemon.destroy
    end
  end

  # ================================================================================
  # IMAGE ATTACHMENT TESTS
  # ================================================================================

  test "should support image attachment" do
    pokemon = pokemons(:pikachu)
    assert_respond_to pokemon, :image
  end

  test "should allow pokemon without image" do
    pokemon = Pokemon.new(pokedex_number: 99, name: "Kingler", difficulty: 2)
    assert pokemon.save
    assert_not pokemon.image.attached?
  end

  # ================================================================================
  # EDGE CASE TESTS
  # ================================================================================

  test "should handle pokemon update" do
    pokemon = pokemons(:bulbasaur)
    pokemon.update(name: "Ivysaur")
    assert pokemon.valid?
    assert_equal "Ivysaur", pokemon.name
  end

  test "should not allow updating to duplicate pokedex_number" do
    pokemon1 = pokemons(:bulbasaur)
    pokemon2 = pokemons(:charmander)

    pokemon2.pokedex_number = pokemon1.pokedex_number
    assert_not pokemon2.save
  end

  test "should allow pokemon with all valid edge values" do
    pokemon = Pokemon.new(pokedex_number: 151, name: "Z", difficulty: 5)
    pokemons(:mew).destroy # Remove existing pokemon at 151
    assert pokemon.save
  end
end
