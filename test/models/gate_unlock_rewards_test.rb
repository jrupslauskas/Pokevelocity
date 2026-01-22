require "test_helper"

class GateUnlockRewardsTest < ActiveSupport::TestCase
  def setup
    @trainer = trainers(:ash)
  end

  # Helper method to give trainer enough difficulty score for a gate
  def reach_difficulty_score(target_score)
    current_score = @trainer.difficulty_score
    return if current_score >= target_score

    needed_score = target_score - current_score
    # Create Pokemon with difficulty 5 to reach target
    pokemon_needed = (needed_score / 5.0).ceil

    # Use valid Pokedex numbers (1-151)
    # Start from a number that won't conflict with already-captured Pokemon
    base_num = 50 + @trainer.captured_pokemon.count
    pokemon_needed.times do |i|
      pokedex_num = (base_num + i) % 151 + 1  # Cycle through 1-151
      pokemon = Pokemon.find_or_create_by!(pokedex_number: pokedex_num) do |p|
        p.name = "TestPokemon#{pokedex_num}"
        p.difficulty = 5
      end
      # Skip if already captured (avoid duplicate error)
      next if @trainer.captured_pokemon.exists?(id: pokemon.id)
      @trainer.captures.create!(pokemon: pokemon, ball_type: "pokeball")
    end
  end

  # Helper to create a gate with required score
  def create_gate(gate_number, required_score)
    Gate.find_or_create_by!(gate_number: gate_number) do |g|
      g.required_difficulty_score = required_score
    end
  end

  # ================================================================================
  # GATE 1: Pokéball
  # ================================================================================

  test "Gate 1 should award 1 Pokéball" do
    gate_1 = create_gate(1, 8)
    initial_pokeballs = @trainer.item_quantity(:pokeball)

    reach_difficulty_score(gate_1.required_difficulty_score)
    @trainer.unlock_gate!(gate_1)

    assert_equal initial_pokeballs + 1, @trainer.item_quantity(:pokeball)
  end

  # ================================================================================
  # GATE 2: 100 Currency + Old Rod + Potion
  # ================================================================================

  test "Gate 2 should award 100 currency" do
    gate_2 = create_gate(2, 17)
    initial_currency = @trainer.currency

    reach_difficulty_score(gate_2.required_difficulty_score)
    @trainer.unlock_gate!(gate_2)

    @trainer.reload
    assert_equal initial_currency + 100, @trainer.currency
  end

  test "Gate 2 should award Old Rod" do
    gate_2 = create_gate(2, 17)
    Item.find_or_create_by(key: "old_rod", item_type: "key_item")

    assert_not @trainer.has_item?(:old_rod)

    reach_difficulty_score(gate_2.required_difficulty_score)
    @trainer.unlock_gate!(gate_2)

    assert @trainer.has_item?(:old_rod)
  end

  test "Gate 2 should award 1 Potion" do
    gate_2 = create_gate(2, 17)
    Item.find_or_create_by(key: "potion", item_type: "potion")
    initial_potions = @trainer.item_quantity(:potion)

    reach_difficulty_score(gate_2.required_difficulty_score)
    @trainer.unlock_gate!(gate_2)

    assert_equal initial_potions + 1, @trainer.item_quantity(:potion)
  end

  test "Gate 2 should award Old Rod, Potion, and 100 currency" do
    gate_2 = create_gate(2, 17)
    Item.find_or_create_by(key: "old_rod", item_type: "key_item")
    Item.find_or_create_by(key: "potion", item_type: "potion")
    initial_currency = @trainer.currency
    initial_potions = @trainer.item_quantity(:potion)

    reach_difficulty_score(gate_2.required_difficulty_score)
    @trainer.unlock_gate!(gate_2)

    assert @trainer.has_item?(:old_rod)
    assert_equal initial_potions + 1, @trainer.item_quantity(:potion)
    @trainer.reload
    assert_equal initial_currency + 100, @trainer.currency
  end

  # ================================================================================
  # GATE 3: Evolution Stone
  # ================================================================================

  test "Gate 3 should award 1 Evolution Stone" do
    gate_3 = create_gate(3, 25)
    Item.find_or_create_by(key: "evolution_stone", item_type: "key_item")
    initial_stones = @trainer.item_quantity(:evolution_stone)

    reach_difficulty_score(gate_3.required_difficulty_score)
    @trainer.unlock_gate!(gate_3)

    assert_equal initial_stones + 1, @trainer.item_quantity(:evolution_stone)
  end

  # ================================================================================
  # GATE 4: Great Ball + Good Rod
  # ================================================================================

  test "Gate 4 should award 1 Great Ball" do
    gate_4 = create_gate(4, 32)
    Item.find_or_create_by(key: "great_ball", item_type: "pokeball")
    initial_great_balls = @trainer.item_quantity(:great_ball)

    reach_difficulty_score(gate_4.required_difficulty_score)
    @trainer.unlock_gate!(gate_4)

    assert_equal initial_great_balls + 1, @trainer.item_quantity(:great_ball)
  end

  test "Gate 4 should award Good Rod" do
    gate_4 = create_gate(4, 32)
    Item.find_or_create_by(key: "good_rod", item_type: "key_item")

    assert_not @trainer.has_item?(:good_rod)

    reach_difficulty_score(gate_4.required_difficulty_score)
    @trainer.unlock_gate!(gate_4)

    assert @trainer.has_item?(:good_rod)
  end

  test "Gate 4 should award both Great Ball and Good Rod" do
    gate_4 = create_gate(4, 32)
    Item.find_or_create_by(key: "great_ball", item_type: "pokeball")
    Item.find_or_create_by(key: "good_rod", item_type: "key_item")
    initial_great_balls = @trainer.item_quantity(:great_ball)

    reach_difficulty_score(gate_4.required_difficulty_score)
    @trainer.unlock_gate!(gate_4)

    assert_equal initial_great_balls + 1, @trainer.item_quantity(:great_ball)
    assert @trainer.has_item?(:good_rod)
  end

  # ================================================================================
  # GATE 5: 200 Currency + HM Surf + Super Potion
  # ================================================================================

  test "Gate 5 should award 200 currency" do
    gate_5 = create_gate(5, 40)
    initial_currency = @trainer.currency

    reach_difficulty_score(gate_5.required_difficulty_score)
    @trainer.unlock_gate!(gate_5)

    @trainer.reload
    assert_equal initial_currency + 200, @trainer.currency
  end

  test "Gate 5 should award HM Surf" do
    gate_5 = create_gate(5, 40)
    Item.find_or_create_by(key: "hm_surf", item_type: "key_item")

    assert_not @trainer.has_item?(:hm_surf)

    reach_difficulty_score(gate_5.required_difficulty_score)
    @trainer.unlock_gate!(gate_5)

    assert @trainer.has_item?(:hm_surf)
  end

  test "Gate 5 should award 1 Super Potion" do
    gate_5 = create_gate(5, 40)
    Item.find_or_create_by(key: "super_potion", item_type: "potion")
    initial_super_potions = @trainer.item_quantity(:super_potion)

    reach_difficulty_score(gate_5.required_difficulty_score)
    @trainer.unlock_gate!(gate_5)

    assert_equal initial_super_potions + 1, @trainer.item_quantity(:super_potion)
  end

  test "Gate 5 should award HM Surf, Super Potion, and 200 currency" do
    gate_5 = create_gate(5, 40)
    Item.find_or_create_by(key: "hm_surf", item_type: "key_item")
    Item.find_or_create_by(key: "super_potion", item_type: "potion")
    initial_currency = @trainer.currency
    initial_super_potions = @trainer.item_quantity(:super_potion)

    reach_difficulty_score(gate_5.required_difficulty_score)
    @trainer.unlock_gate!(gate_5)

    assert @trainer.has_item?(:hm_surf)
    assert_equal initial_super_potions + 1, @trainer.item_quantity(:super_potion)
    @trainer.reload
    assert_equal initial_currency + 200, @trainer.currency
  end

  # ================================================================================
  # GATE 6: 2 Evolution Stones + Super Rod
  # ================================================================================

  test "Gate 6 should award 2 Evolution Stones" do
    gate_6 = create_gate(6, 48)
    Item.find_or_create_by(key: "evolution_stone", item_type: "key_item")
    initial_stones = @trainer.item_quantity(:evolution_stone)

    reach_difficulty_score(gate_6.required_difficulty_score)
    @trainer.unlock_gate!(gate_6)

    assert_equal initial_stones + 2, @trainer.item_quantity(:evolution_stone)
  end

  test "Gate 6 should award Super Rod" do
    gate_6 = create_gate(6, 48)
    Item.find_or_create_by(key: "super_rod", item_type: "key_item")

    assert_not @trainer.has_item?(:super_rod)

    reach_difficulty_score(gate_6.required_difficulty_score)
    @trainer.unlock_gate!(gate_6)

    assert @trainer.has_item?(:super_rod)
  end

  test "Gate 6 should award both 2 Evolution Stones and Super Rod" do
    gate_6 = create_gate(6, 48)
    Item.find_or_create_by(key: "evolution_stone", item_type: "key_item")
    Item.find_or_create_by(key: "super_rod", item_type: "key_item")
    initial_stones = @trainer.item_quantity(:evolution_stone)

    reach_difficulty_score(gate_6.required_difficulty_score)
    @trainer.unlock_gate!(gate_6)

    assert_equal initial_stones + 2, @trainer.item_quantity(:evolution_stone)
    assert @trainer.has_item?(:super_rod)
  end

  # ================================================================================
  # GATE 7: Ultra Ball
  # ================================================================================

  test "Gate 7 should award 1 Ultra Ball" do
    gate_7 = create_gate(7, 55)
    Item.find_or_create_by(key: "ultra_ball", item_type: "pokeball")
    initial_ultra_balls = @trainer.item_quantity(:ultra_ball)

    reach_difficulty_score(gate_7.required_difficulty_score)
    @trainer.unlock_gate!(gate_7)

    assert_equal initial_ultra_balls + 1, @trainer.item_quantity(:ultra_ball)
  end

  # ================================================================================
  # GATE 8: 500 Currency
  # ================================================================================

  test "Gate 8 should award 500 currency" do
    gate_8 = create_gate(8, 62)
    initial_currency = @trainer.currency

    reach_difficulty_score(gate_8.required_difficulty_score)
    @trainer.unlock_gate!(gate_8)

    @trainer.reload
    assert_equal initial_currency + 500, @trainer.currency
  end

  # ================================================================================
  # GATE 9: Master Ball
  # ================================================================================

  test "Gate 9 should award 1 Master Ball" do
    gate_9 = create_gate(9, 75)
    Item.find_or_create_by(key: "master_ball", item_type: "pokeball")
    initial_master_balls = @trainer.item_quantity(:master_ball)

    reach_difficulty_score(gate_9.required_difficulty_score)
    @trainer.unlock_gate!(gate_9)

    assert_equal initial_master_balls + 1, @trainer.item_quantity(:master_ball)
  end

  # ================================================================================
  # COMBINED TESTS
  # ================================================================================

  test "should not receive duplicate items if already owned" do
    gate_2 = create_gate(2, 17)
    Item.find_or_create_by(key: "old_rod", item_type: "key_item")

    # Give trainer Old Rod first
    @trainer.add_item(:old_rod, 1)
    initial_quantity = @trainer.item_quantity(:old_rod)

    reach_difficulty_score(gate_2.required_difficulty_score)
    @trainer.unlock_gate!(gate_2)

    # Should still have same quantity (not duplicated)
    assert_equal initial_quantity, @trainer.item_quantity(:old_rod)
  end

  test "auto_unlock_gates! should award all rewards for multiple gates" do
    gate_1 = create_gate(1, 8)
    gate_2 = create_gate(2, 17)
    gate_3 = create_gate(3, 25)
    Item.find_or_create_by(key: "old_rod", item_type: "key_item")
    Item.find_or_create_by(key: "evolution_stone", item_type: "key_item")
    Item.find_or_create_by(key: "potion", item_type: "potion")

    # Ensure gates aren't already unlocked
    @trainer.gate_unlocks.where(gate: [ gate_1, gate_2, gate_3 ]).destroy_all

    initial_pokeballs = @trainer.item_quantity(:pokeball)
    initial_stones = @trainer.item_quantity(:evolution_stone)
    initial_potions = @trainer.item_quantity(:potion)
    initial_currency = @trainer.currency

    # Reach difficulty for Gate 3 (which unlocks 1, 2, and 3)
    reach_difficulty_score(gate_3.required_difficulty_score)

    # Auto-unlock all gates
    newly_unlocked = @trainer.auto_unlock_gates!

    # Should unlock all 3 gates
    assert_equal 3, newly_unlocked.length

    # Gate 1: 1 pokeball
    # Gate 2: 100 currency + Old Rod + 1 Potion
    # Gate 3: 1 evolution stone
    assert_equal initial_pokeballs + 1, @trainer.item_quantity(:pokeball)
    assert_equal initial_stones + 1, @trainer.item_quantity(:evolution_stone)
    assert_equal initial_potions + 1, @trainer.item_quantity(:potion)
    @trainer.reload
    assert_equal initial_currency + 100, @trainer.currency
    assert @trainer.has_item?(:old_rod)
  end

  test "unlocking all gates should accumulate all rewards correctly" do
    # Create all gates
    gates = [
      create_gate(1, 8),
      create_gate(2, 17),
      create_gate(3, 25),
      create_gate(4, 32),
      create_gate(5, 40),
      create_gate(6, 48),
      create_gate(7, 55),
      create_gate(8, 62),
      create_gate(9, 75)
    ]

    # Create all required items
    Item.find_or_create_by(key: "old_rod", item_type: "key_item")
    Item.find_or_create_by(key: "good_rod", item_type: "key_item")
    Item.find_or_create_by(key: "super_rod", item_type: "key_item")
    Item.find_or_create_by(key: "hm_surf", item_type: "key_item")
    Item.find_or_create_by(key: "evolution_stone", item_type: "key_item")
    Item.find_or_create_by(key: "great_ball", item_type: "pokeball")
    Item.find_or_create_by(key: "ultra_ball", item_type: "pokeball")
    Item.find_or_create_by(key: "master_ball", item_type: "pokeball")
    Item.find_or_create_by(key: "potion", item_type: "potion")
    Item.find_or_create_by(key: "super_potion", item_type: "potion")

    # Ensure gates aren't already unlocked
    @trainer.gate_unlocks.destroy_all

    initial_pokeballs = @trainer.item_quantity(:pokeball)
    initial_great_balls = @trainer.item_quantity(:great_ball)
    initial_ultra_balls = @trainer.item_quantity(:ultra_ball)
    initial_master_balls = @trainer.item_quantity(:master_ball)
    initial_stones = @trainer.item_quantity(:evolution_stone)
    initial_potions = @trainer.item_quantity(:potion)
    initial_super_potions = @trainer.item_quantity(:super_potion)
    initial_currency = @trainer.currency

    # Reach difficulty for Gate 9 (unlocks all gates)
    reach_difficulty_score(75)

    # Auto-unlock all gates
    newly_unlocked = @trainer.auto_unlock_gates!

    # Should unlock all 9 gates
    assert_equal 9, newly_unlocked.length

    # Check all rewards:
    # Gate 1: 1 pokeball
    # Gate 2: 100 currency + Old Rod + 1 Potion
    # Gate 3: 1 evolution stone
    # Gate 4: 1 great ball + Good Rod
    # Gate 5: 200 currency + HM Surf + 1 Super Potion
    # Gate 6: 2 evolution stones + Super Rod
    # Gate 7: 1 ultra ball
    # Gate 8: 500 currency
    # Gate 9: 1 master ball

    assert_equal initial_pokeballs + 1, @trainer.item_quantity(:pokeball)
    assert_equal initial_great_balls + 1, @trainer.item_quantity(:great_ball)
    assert_equal initial_ultra_balls + 1, @trainer.item_quantity(:ultra_ball)
    assert_equal initial_master_balls + 1, @trainer.item_quantity(:master_ball)
    assert_equal initial_stones + 3, @trainer.item_quantity(:evolution_stone) # 1 + 2 = 3
    assert_equal initial_potions + 1, @trainer.item_quantity(:potion)
    assert_equal initial_super_potions + 1, @trainer.item_quantity(:super_potion)

    @trainer.reload
    assert_equal initial_currency + 800, @trainer.currency # 100 + 200 + 500 = 800

    assert @trainer.has_item?(:old_rod)
    assert @trainer.has_item?(:good_rod)
    assert @trainer.has_item?(:super_rod)
    assert @trainer.has_item?(:hm_surf)
  end
end
