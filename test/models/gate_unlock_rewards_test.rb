require "test_helper"

class GateUnlockRewardsTest < ActiveSupport::TestCase
  def setup
    @trainer = trainers(:ash)

    # Find or create Gate 6
    @gate_6 = Gate.find_by(gate_number: 6) || Gate.create!(
      gate_number: 6,
      required_difficulty_score: 50
    )

    # Find or create Gate 1 for comparison tests
    @gate_1 = Gate.find_by(gate_number: 1) || Gate.create!(
      gate_number: 1,
      required_difficulty_score: 5
    )

    # Create HM03 Surf item if it doesn't exist
    @hm_surf = Item.find_or_create_by!(key: "hm_surf", item_type: "key_item")
  end

  # Helper method to give trainer enough difficulty score for a gate
  def reach_difficulty_score(target_score)
    current_score = @trainer.difficulty_score
    return if current_score >= target_score

    needed_score = target_score - current_score
    # Create Pokemon with difficulty 5 to reach target
    pokemon_needed = (needed_score / 5.0).ceil

    # Use valid Pokedex numbers (1-151)
    base_num = 50
    pokemon_needed.times do |i|
      pokedex_num = (base_num + i) % 151 + 1  # Cycle through 1-151
      pokemon = Pokemon.find_or_create_by!(pokedex_number: pokedex_num) do |p|
        p.name = "TestPokemon#{pokedex_num}"
        p.difficulty = 5
      end
      # Skip if already captured (avoid duplicate error)
      next if @trainer.captured_pokemon.exists?(id: pokemon.id)
      @trainer.captures.create!(pokemon: pokemon, ball_type: 'pokeball')
    end
  end

  test "trainer should receive HM03 Surf when unlocking Gate 6" do
    # Ensure trainer doesn't have HM Surf yet
    assert_not @trainer.has_item?(:hm_surf)

    # Reach Gate 6's difficulty requirement
    reach_difficulty_score(@gate_6.required_difficulty_score)

    # Unlock the gate
    @trainer.unlock_gate!(@gate_6)

    # Trainer should now have HM Surf
    assert @trainer.has_item?(:hm_surf)
  end

  test "trainer should receive exactly one HM03 Surf when unlocking Gate 6" do
    # Reach Gate 6's difficulty requirement
    reach_difficulty_score(@gate_6.required_difficulty_score)

    # Unlock the gate
    @trainer.unlock_gate!(@gate_6)

    # Should have exactly 1 HM Surf
    assert_equal 1, @trainer.item_quantity(:hm_surf)
  end

  test "trainer should not receive duplicate HM03 Surf if already owned" do
    # Give trainer HM Surf first
    @trainer.add_item(:hm_surf, 1)
    initial_quantity = @trainer.item_quantity(:hm_surf)

    # Reach Gate 6's difficulty requirement
    reach_difficulty_score(@gate_6.required_difficulty_score)

    # Unlock the gate
    @trainer.unlock_gate!(@gate_6)

    # Should still have same quantity
    assert_equal initial_quantity, @trainer.item_quantity(:hm_surf)
  end

  test "trainer should not receive HM03 Surf when unlocking other gates" do
    # Reach Gate 1's difficulty requirement
    reach_difficulty_score(@gate_1.required_difficulty_score)

    # Unlock Gate 1
    @trainer.unlock_gate!(@gate_1)

    # Should not have HM Surf from Gate 1
    assert_not @trainer.has_item?(:hm_surf)
  end

  test "auto_unlock_gates! should award HM03 Surf when Gate 6 is auto-unlocked" do
    # Ensure trainer doesn't have HM Surf yet
    assert_not @trainer.has_item?(:hm_surf)

    # Reach Gate 6's difficulty requirement
    reach_difficulty_score(@gate_6.required_difficulty_score)

    # Auto-unlock gates
    newly_unlocked = @trainer.auto_unlock_gates!

    # Gate 6 should be in the newly unlocked list
    assert_includes newly_unlocked, @gate_6

    # Trainer should now have HM Surf
    assert @trainer.has_item?(:hm_surf)
  end
end
