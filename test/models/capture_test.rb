require "test_helper"

class CaptureTest < ActiveSupport::TestCase
  # ================================================================================
  # VALID MODEL TESTS
  # ================================================================================

  test "should save valid capture" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: "pokeball"
    )
    assert capture.save
  end

  test "should load gary_charmander fixture" do
    capture = captures(:gary_charmander)
    assert capture.valid?
    assert_equal trainers(:gary), capture.trainer
    assert_equal pokemons(:charmander), capture.pokemon
    assert_equal "pokeball", capture.ball_type
  end

  test "should load gary_squirtle fixture" do
    capture = captures(:gary_squirtle)
    assert capture.valid?
    assert_equal trainers(:gary), capture.trainer
    assert_equal pokemons(:squirtle), capture.pokemon
    assert_equal "great_ball", capture.ball_type
  end

  # ================================================================================
  # BALL TYPE PRESENCE VALIDATION TESTS
  # ================================================================================

  test "should require ball_type to be present" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: nil
    )
    assert_not capture.save
  end

  test "should add error when ball_type is nil" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: nil
    )
    capture.save
    assert_includes capture.errors[:ball_type], "can't be blank"
  end

  test "should not save with empty ball_type" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: ""
    )
    assert_not capture.save
  end

  # ================================================================================
  # BALL TYPE INCLUSION VALIDATION TESTS
  # ================================================================================

  test "should accept pokeball as ball_type" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: "pokeball"
    )
    assert capture.save
  end

  test "should accept great_ball as ball_type" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: "great_ball"
    )
    assert capture.save
  end

  test "should accept ultra_ball as ball_type" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: "ultra_ball"
    )
    assert capture.save
  end

  test "should accept master_ball as ball_type" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: "master_ball"
    )
    assert capture.save
  end

  test "should not accept invalid ball_type" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: "superball"
    )
    assert_not capture.save
  end

  test "should add error when ball_type is invalid" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: "invalid_ball"
    )
    capture.save
    assert_includes capture.errors[:ball_type], "is not included in the list"
  end

  test "should not accept ball_type with different case" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: "Pokeball" # Capital P
    )
    assert_not capture.save
  end

  # ================================================================================
  # BALL_TYPES CONSTANT TESTS
  # ================================================================================

  test "should have BALL_TYPES constant" do
    assert_equal %w[pokeball great_ball ultra_ball master_ball], Capture::BALL_TYPES
  end

  test "should freeze BALL_TYPES constant" do
    assert Capture::BALL_TYPES.frozen?
  end

  # ================================================================================
  # CAPTURED_AT PRESENCE VALIDATION TESTS
  # ================================================================================

  test "should require captured_at to be present" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: "pokeball",
      captured_at: nil
    )
    # This should still save because the before_validation callback sets it
    assert capture.save
    assert_not_nil capture.captured_at
  end

  test "should automatically set captured_at on create" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: "pokeball"
    )
    assert_nil capture.captured_at
    capture.save
    assert_not_nil capture.captured_at
  end

  test "should set captured_at to current time" do
    freeze_time = Time.current
    travel_to freeze_time do
      capture = Capture.create(
        trainer: trainers(:ash),
        pokemon: pokemons(:bulbasaur),
        ball_type: "pokeball"
      )
      assert_in_delta freeze_time.to_f, capture.captured_at.to_f, 1.0
    end
  end

  test "should not override manually set captured_at" do
    custom_time = 1.day.ago
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemons(:bulbasaur),
      ball_type: "pokeball",
      captured_at: custom_time
    )
    capture.save
    assert_equal custom_time.to_i, capture.captured_at.to_i
  end

  # ================================================================================
  # UNIQUENESS VALIDATION TESTS
  # ================================================================================

  test "should not allow trainer to capture same pokemon twice" do
    trainer = trainers(:gary)
    pokemon = pokemons(:charmander)

    # Gary already captured Charmander in fixtures
    duplicate_capture = Capture.new(
      trainer: trainer,
      pokemon: pokemon,
      ball_type: "great_ball"
    )
    assert_not duplicate_capture.save
  end

  test "should add error when pokemon already captured by trainer" do
    trainer = trainers(:gary)
    pokemon = pokemons(:charmander)

    duplicate_capture = Capture.new(
      trainer: trainer,
      pokemon: pokemon,
      ball_type: "great_ball"
    )
    duplicate_capture.save
    assert_includes duplicate_capture.errors[:pokemon_id], "has already been captured by this trainer"
  end

  test "should allow different trainers to capture same pokemon" do
    pokemon = pokemons(:charmander)
    # Gary already captured Charmander
    # Ash should be able to capture it too

    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: pokemon,
      ball_type: "ultra_ball"
    )
    assert capture.save
  end

  test "should allow same trainer to capture different pokemon" do
    trainer = trainers(:gary)
    # Gary already captured Charmander and Squirtle
    # Gary should be able to capture Bulbasaur

    capture = Capture.new(
      trainer: trainer,
      pokemon: pokemons(:bulbasaur),
      ball_type: "pokeball"
    )
    assert capture.save
  end

  # ================================================================================
  # ASSOCIATION TESTS
  # ================================================================================

  test "should belong to trainer" do
    capture = captures(:gary_charmander)
    assert_respond_to capture, :trainer
    assert_equal trainers(:gary), capture.trainer
  end

  test "should belong to pokemon" do
    capture = captures(:gary_charmander)
    assert_respond_to capture, :pokemon
    assert_equal pokemons(:charmander), capture.pokemon
  end

  test "should require trainer association" do
    capture = Capture.new(
      trainer: nil,
      pokemon: pokemons(:bulbasaur),
      ball_type: "pokeball"
    )
    assert_not capture.save
  end

  test "should require pokemon association" do
    capture = Capture.new(
      trainer: trainers(:ash),
      pokemon: nil,
      ball_type: "pokeball"
    )
    assert_not capture.save
  end

  test "should be destroyed when trainer is destroyed" do
    trainer = trainers(:gary)
    capture_ids = trainer.captures.pluck(:id)

    assert_difference("Capture.count", -capture_ids.count) do
      trainer.destroy
    end

    capture_ids.each do |capture_id|
      assert_nil Capture.find_by(id: capture_id)
    end
  end

  test "should be destroyed when pokemon is destroyed" do
    pokemon = pokemons(:charmander)
    capture_count = pokemon.captures.count

    assert_difference("Capture.count", -capture_count) do
      pokemon.destroy
    end
  end

  # ================================================================================
  # EDGE CASE TESTS
  # ================================================================================

  test "should handle capture update" do
    capture = captures(:gary_charmander)
    capture.update(ball_type: "master_ball")
    assert capture.valid?
    assert_equal "master_ball", capture.ball_type
  end

  test "should not allow updating to invalid ball_type" do
    capture = captures(:gary_charmander)
    capture.ball_type = "invalid_ball"
    assert_not capture.save
  end

  test "should allow capturing multiple pokemon with same ball_type" do
    trainer = trainers(:ash)

    capture1 = Capture.create(
      trainer: trainer,
      pokemon: pokemons(:bulbasaur),
      ball_type: "pokeball"
    )

    capture2 = Capture.create(
      trainer: trainer,
      pokemon: pokemons(:pikachu),
      ball_type: "pokeball"
    )

    assert capture1.valid?
    assert capture2.valid?
  end

  test "should store captured_at as datetime" do
    capture = captures(:gary_charmander)
    assert_instance_of ActiveSupport::TimeWithZone, capture.captured_at
  end
end
