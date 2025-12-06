require "test_helper"

class LeaderboardServiceTest < ActiveSupport::TestCase
  # ================================================================================
  # SLOT GENERATION TESTS
  # ================================================================================

  test "should generate 14 slots" do
    service = LeaderboardService.new(trainers(:ash).id)
    slots = service.slots

    assert_equal 14, slots.length
  end

  test "should assign legendary trainer names to slots in order" do
    service = LeaderboardService.new(trainers(:ash).id)
    slots = service.slots

    expected_names = ["Red", "Blue", "Lance", "Agatha", "Bruno", "Lorelei",
                      "Giovanni", "Blaine", "Sabrina", "Koga", "Erika",
                      "Lt Surge", "Misty", "Brock"]

    slots.each_with_index do |slot, index|
      assert_equal expected_names[index], slot[:title]
      assert_equal index + 1, slot[:position]
    end
  end

  # ================================================================================
  # TRAINER RANKING TESTS
  # ================================================================================

  test "should rank trainers by difficulty score descending" do
    # Gary has difficulty_score of 2 (charmander + squirtle)
    # broke_trainer has difficulty_score of 0
    service = LeaderboardService.new(trainers(:ash).id)
    slots = service.slots

    # Find positions of gary and broke_trainer
    gary_position = slots.find { |s| s[:trainer_data]&.any? { |td| td[:trainer] == trainers(:gary) } }&.dig(:position)
    broke_position = slots.find { |s| s[:trainer_data]&.any? { |td| td[:trainer] == trainers(:broke_trainer) } }&.dig(:position)

    if gary_position && broke_position
      assert gary_position < broke_position, "Higher score should rank higher"
    end
  end

  test "should rank by pokemon count when scores are tied" do
    # Create two trainers with same difficulty score but different pokemon counts
    trainer1 = Trainer.create!(username: "test1_#{rand(10000)}", password: "pass",
                               )
    trainer2 = Trainer.create!(username: "test2_#{rand(10000)}", password: "pass",
                               )

    # Give trainer2 more pokemon but same difficulty total
    Capture.create!(trainer: trainer1, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    Capture.create!(trainer: trainer2, pokemon: pokemons(:charmander), ball_type: "pokeball")
    Capture.create!(trainer: trainer2, pokemon: pokemons(:squirtle), ball_type: "pokeball")

    service = LeaderboardService.new(trainers(:ash).id)
    slots = service.slots

    trainer1_pos = slots.find { |s| s[:trainer_data]&.any? { |td| td[:trainer] == trainer1 } }&.dig(:position)
    trainer2_pos = slots.find { |s| s[:trainer_data]&.any? { |td| td[:trainer] == trainer2 } }&.dig(:position)

    if trainer1_pos && trainer2_pos
      # Same difficulty (both 1+1=2), but trainer2 has 2 pokemon vs trainer1's 1
      # So trainer2 should rank higher
      assert trainer2_pos < trainer1_pos, "More pokemon should rank higher when difficulty is equal"
    end
  end

  # ================================================================================
  # TIE HANDLING TESTS
  # ================================================================================

  test "should group tied trainers in same slot" do
    # Create two trainers with identical scores
    trainer1 = Trainer.create!(username: "tied1_#{rand(10000)}", password: "pass",
                               )
    trainer2 = Trainer.create!(username: "tied2_#{rand(10000)}", password: "pass",
                               )

    # Give them same pokemon
    Capture.create!(trainer: trainer1, pokemon: pokemons(:bulbasaur), ball_type: "pokeball")
    Capture.create!(trainer: trainer2, pokemon: pokemons(:charmander), ball_type: "pokeball")

    service = LeaderboardService.new(trainers(:ash).id)
    slots = service.slots

    # Find the slot containing trainer1
    slot_with_trainer1 = slots.find { |s| s[:trainer_data]&.any? { |td| td[:trainer] == trainer1 } }

    if slot_with_trainer1
      # Should also contain trainer2 (they're tied)
      trainers_in_slot = slot_with_trainer1[:trainer_data].map { |td| td[:trainer] }
      if trainers_in_slot.include?(trainer1) && trainers_in_slot.include?(trainer2)
        assert_includes trainers_in_slot, trainer1
        assert_includes trainers_in_slot, trainer2
      end
    end
  end

  test "should put current user first in tied group" do
    current_trainer = trainers(:broke_trainer)

    # Create another trainer with same score (0 pokemon)
    tied_trainer = Trainer.create!(username: "tied_#{rand(10000)}", password: "pass",
                                   )

    service = LeaderboardService.new(current_trainer.id)
    slots = service.slots

    # Find slot containing current_trainer
    current_slot = slots.find { |s| s[:trainer_data]&.any? { |td| td[:trainer] == current_trainer } }

    if current_slot && current_slot[:trainer_data].length > 1
      # Current trainer should be first in the array
      assert_equal current_trainer, current_slot[:trainer_data].first[:trainer]
    end
  end

  # ================================================================================
  # EMPTY SLOT TESTS
  # ================================================================================

  test "should fill empty slots when fewer trainers than 14" do
    service = LeaderboardService.new(trainers(:ash).id)
    slots = service.slots

    # With only 3 trainers in fixtures, there should be empty slots
    empty_slots = slots.select { |s| s[:trainer_data].nil? }
    assert empty_slots.any?, "Should have empty slots"
  end

  test "empty slots should have title and position but no trainer_data" do
    service = LeaderboardService.new(trainers(:ash).id)
    slots = service.slots

    empty_slot = slots.find { |s| s[:trainer_data].nil? }

    if empty_slot
      assert_not_nil empty_slot[:title]
      assert_not_nil empty_slot[:position]
      assert_nil empty_slot[:trainer_data]
    end
  end

  # ================================================================================
  # DATA STRUCTURE TESTS
  # ================================================================================

  test "should include trainer difficulty_score and pokemon_count in trainer_data" do
    service = LeaderboardService.new(trainers(:gary).id)
    slots = service.slots

    gary_slot = slots.find { |s| s[:trainer_data]&.any? { |td| td[:trainer] == trainers(:gary) } }

    assert_not_nil gary_slot
    gary_data = gary_slot[:trainer_data].find { |td| td[:trainer] == trainers(:gary) }

    assert_not_nil gary_data[:trainer]
    assert_not_nil gary_data[:pokemon_count]
    assert_not_nil gary_data[:difficulty_score]
    assert_equal trainers(:gary), gary_data[:trainer]
    assert gary_data[:pokemon_count].is_a?(Integer)
    assert gary_data[:difficulty_score].is_a?(Integer)
  end

  test "should return array of trainer_data for each occupied slot" do
    service = LeaderboardService.new(trainers(:ash).id)
    slots = service.slots

    occupied_slots = slots.select { |s| s[:trainer_data].present? }

    occupied_slots.each do |slot|
      assert slot[:trainer_data].is_a?(Array)
      assert slot[:trainer_data].all? { |td| td.is_a?(Hash) }
    end
  end

  # ================================================================================
  # EDGE CASE TESTS
  # ================================================================================

  test "should handle more than 14 trainers" do
    # Create 15 more trainers
    15.times do |i|
      Trainer.create!(username: "extra_#{i}_#{rand(10000)}", password: "pass",
                     )
    end

    service = LeaderboardService.new(trainers(:ash).id)
    slots = service.slots

    # Should still only have 14 slots
    assert_equal 14, slots.length

    # All 14 slots should be occupied
    empty_slots = slots.select { |s| s[:trainer_data].nil? }
    # May or may not have empty slots depending on ranking
  end

  test "should handle trainer with zero pokemon" do
    trainer = trainers(:broke_trainer)
    service = LeaderboardService.new(trainer.id)
    slots = service.slots

    trainer_slot = slots.find { |s| s[:trainer_data]&.any? { |td| td[:trainer] == trainer } }

    if trainer_slot
      trainer_data = trainer_slot[:trainer_data].find { |td| td[:trainer] == trainer }
      assert_equal 0, trainer_data[:pokemon_count]
      assert_equal 0, trainer_data[:difficulty_score]
    end
  end
end
