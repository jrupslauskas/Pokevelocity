require "test_helper"

class PokeballRewardServiceTest < ActiveSupport::TestCase
  # ================================================================================
  # BALL INCREMENT TESTS
  # ================================================================================

  test "should increment some ball count" do
    trainer = trainers(:ash)
    initial_total = trainer.total_pokeballs

    # Award a ball (any type)
    PokeballRewardService.new(trainer, 1).award!

    trainer.reload
    assert_equal initial_total + 1, trainer.total_pokeballs
  end

  test "should increment one of the valid ball types for story points" do
    trainer = trainers(:ash)

    # For 1 point, can get pokeball, great_ball, ultra_ball, or master_ball
    result = PokeballRewardService.new(trainer, 1).award!
    assert_includes %w[pokeball great_ball ultra_ball master_ball], result[:ball_type]

    # For 5 points, can get great_ball, ultra_ball, or master_ball
    result = PokeballRewardService.new(trainer, 5).award!
    assert_includes %w[great_ball ultra_ball master_ball], result[:ball_type]

    # For 8 points, can get ultra_ball or master_ball
    result = PokeballRewardService.new(trainer, 8).award!
    assert_includes %w[ultra_ball master_ball], result[:ball_type]
  end

  # ================================================================================
  # REWARD WEIGHTS TESTS
  # ================================================================================

  test "reward weights should be defined for standard story points" do
    assert_not_nil PokeballRewardService::REWARD_WEIGHTS[1]
    assert_not_nil PokeballRewardService::REWARD_WEIGHTS[2]
    assert_not_nil PokeballRewardService::REWARD_WEIGHTS[3]
    assert_not_nil PokeballRewardService::REWARD_WEIGHTS[5]
    assert_not_nil PokeballRewardService::REWARD_WEIGHTS[8]
  end

  test "1 point rewards should give all ball types" do
    weights = PokeballRewardService::REWARD_WEIGHTS[1]
    assert_includes weights.keys, "pokeball"
    assert_includes weights.keys, "great_ball"
    assert_includes weights.keys, "ultra_ball"
    assert_includes weights.keys, "master_ball"
    assert_equal 4, weights.keys.length
  end

  test "2 point rewards should give all ball types" do
    weights = PokeballRewardService::REWARD_WEIGHTS[2]
    assert_includes weights.keys, "pokeball"
    assert_includes weights.keys, "great_ball"
    assert_includes weights.keys, "ultra_ball"
    assert_includes weights.keys, "master_ball"
    assert_equal 4, weights.keys.length
  end

  test "3 point rewards should give all ball types" do
    weights = PokeballRewardService::REWARD_WEIGHTS[3]
    assert_includes weights.keys, "pokeball"
    assert_includes weights.keys, "great_ball"
    assert_includes weights.keys, "ultra_ball"
    assert_includes weights.keys, "master_ball"
    assert_equal 4, weights.keys.length
  end

  test "5 point rewards should give great ball, ultra ball, or master ball" do
    weights = PokeballRewardService::REWARD_WEIGHTS[5]
    assert_includes weights.keys, "great_ball"
    assert_includes weights.keys, "ultra_ball"
    assert_includes weights.keys, "master_ball"
    assert_equal 3, weights.keys.length
  end

  test "8 point rewards should only give ultra ball or master ball" do
    weights = PokeballRewardService::REWARD_WEIGHTS[8]
    assert_includes weights.keys, "ultra_ball"
    assert_includes weights.keys, "master_ball"
    assert_equal 2, weights.keys.length
  end

  # ================================================================================
  # DEFAULT WEIGHTS TESTS
  # ================================================================================

  test "should use default weights for non-standard story points" do
    trainer = trainers(:ash)

    # Test 4 points (should use 3 point weights)
    result = PokeballRewardService.new(trainer, 4).award!
    assert_not_nil result[:ball_type]

    # Test 6 points (should use 5 point weights)
    result = PokeballRewardService.new(trainer, 6).award!
    assert_not_nil result[:ball_type]

    # Test 10 points (should use 8 point weights)
    result = PokeballRewardService.new(trainer, 10).award!
    assert_not_nil result[:ball_type]
  end

  test "should use 1 point weights for 0 story points" do
    trainer = trainers(:ash)

    # Test 0 points (should use 1 point weights via default_weights)
    result = PokeballRewardService.new(trainer, 0).award!
    assert_not_nil result[:ball_type]
    # Can get any ball type (same as 1 point)
    assert_includes %w[pokeball great_ball ultra_ball master_ball], result[:ball_type]
  end

  # ================================================================================
  # AWARD RESULT TESTS
  # ================================================================================

  test "should return ball type in result" do
    trainer = trainers(:ash)

    result = PokeballRewardService.new(trainer, 1).award!

    assert_not_nil result[:ball_type]
    assert_includes %w[pokeball great_ball ultra_ball master_ball], result[:ball_type]
  end

  test "should return story points in result" do
    trainer = trainers(:ash)

    result = PokeballRewardService.new(trainer, 5).award!

    assert_equal 5, result[:story_points]
  end

  test "should return new count in result" do
    trainer = trainers(:ash)

    result = PokeballRewardService.new(trainer, 1).award!

    assert_not_nil result[:new_count]
    assert result[:new_count] > 0
  end

  test "should save trainer after awarding ball" do
    trainer = trainers(:ash)
    initial_total = trainer.total_pokeballs

    PokeballRewardService.new(trainer, 1).award!

    trainer.reload
    assert_equal initial_total + 1, trainer.total_pokeballs
  end

  # ================================================================================
  # WEIGHTED RANDOM SELECTION TESTS
  # ================================================================================

  test "should select ball type based on weights" do
    trainer = trainers(:ash)

    # Run multiple times to ensure randomness works
    results = 100.times.map do
      PokeballRewardService.new(trainer, 1).award![:ball_type]
    end

    # For 1 point, can get any ball type
    results.each do |ball_type|
      assert_includes %w[pokeball great_ball ultra_ball master_ball], ball_type
    end

    # Should have some distribution (not all the same)
    assert results.uniq.length > 1, "Expected some variety in ball types"
  end

  test "should respect weight distribution for 1 point rewards" do
    trainer = trainers(:ash)

    results = 1000.times.map do
      trainer.reload
      PokeballRewardService.new(trainer, 1).award![:ball_type]
    end

    pokeball_count = results.count("pokeball")
    great_ball_count = results.count("great_ball")
    ultra_ball_count = results.count("ultra_ball")
    master_ball_count = results.count("master_ball")

    # Weights are 80/10/5/5, so pokeballs should be ~8x more common than great balls
    # Allow for some randomness variance
    ratio = pokeball_count.to_f / great_ball_count
    assert ratio > 4, "Expected pokeballs to be much more common than great balls (got ratio #{ratio})"

    # Ultra and master balls should be rare but present
    assert ultra_ball_count > 0, "Expected some ultra balls in 1000 attempts"
    assert master_ball_count > 0, "Expected some master balls in 1000 attempts"
  end

  # ================================================================================
  # BALL COUNT RETRIEVAL TESTS
  # ================================================================================

  test "should return correct new count after awarding ball" do
    trainer = trainers(:ash)

    result = PokeballRewardService.new(trainer, 1).award!

    # The new_count should match the trainer's current count for that ball type
    trainer.reload
    assert_equal trainer.ball_count(result[:ball_type]), result[:new_count]
  end
end
