require "test_helper"

class GateTest < ActiveSupport::TestCase
  def setup
    @gate = Gate.new(
      gate_number: 7,
      required_difficulty_score: 100
    )
    @trainer = trainers(:ash)
  end

  # Validation Tests
  test "should be valid with valid attributes" do
    assert @gate.valid?
  end

  test "should require gate_number" do
    @gate.gate_number = nil
    assert_not @gate.valid?
    assert_includes @gate.errors[:gate_number], "can't be blank"
  end

  test "should require unique gate_number" do
    @gate.save!
    duplicate_gate = Gate.new(
      gate_number: 7,
      required_difficulty_score: 50
    )
    assert_not duplicate_gate.valid?
    assert_includes duplicate_gate.errors[:gate_number], "has already been taken"
  end

  test "gate_number should be an integer" do
    @gate.gate_number = 3.5
    assert_not @gate.valid?
    assert_includes @gate.errors[:gate_number], "must be an integer"
  end

  test "gate_number should be at least 1" do
    @gate.gate_number = 0
    assert_not @gate.valid?

    @gate.gate_number = 1
    assert @gate.valid?

    # No upper limit - gates can be any number >= 1
    @gate.gate_number = 11
    assert @gate.valid?

    @gate.gate_number = 10
    assert @gate.valid?
  end

  # Name is now loaded from YAML, not stored in database

  test "should require required_difficulty_score" do
    @gate.required_difficulty_score = nil
    assert_not @gate.valid?
    assert_includes @gate.errors[:required_difficulty_score], "can't be blank"
  end

  test "required_difficulty_score should be an integer" do
    @gate.required_difficulty_score = 10.5
    assert_not @gate.valid?
    assert_includes @gate.errors[:required_difficulty_score], "must be an integer"
  end

  test "required_difficulty_score should be non-negative" do
    @gate.required_difficulty_score = -1
    assert_not @gate.valid?

    @gate.required_difficulty_score = 0
    assert @gate.valid?
  end

  # Association Tests
  test "should have many gate_unlocks" do
    assert_respond_to @gate, :gate_unlocks
  end

  test "should have many trainers through gate_unlocks" do
    assert_respond_to @gate, :trainers
  end

  test "should have many routes" do
    assert_respond_to @gate, :routes
  end

  test "should destroy associated gate_unlocks when destroyed" do
    @gate.save!
    unlock = GateUnlock.create!(trainer: @trainer, gate: @gate, unlocked_at: Time.current)

    assert_difference "GateUnlock.count", -1 do
      @gate.destroy
    end
  end

  # Helper Method Tests
  test "unlocked_for? should return true if trainer has unlocked the gate" do
    @gate.save!
    GateUnlock.create!(trainer: @trainer, gate: @gate, unlocked_at: Time.current)

    assert @gate.unlocked_for?(@trainer)
  end

  test "unlocked_for? should return false if trainer has not unlocked the gate" do
    @gate.save!

    assert_not @gate.unlocked_for?(@trainer)
  end

  test "requirement_met_for? should return true if trainer meets difficulty score requirement" do
    # Gary has charmander (difficulty 1) and squirtle (difficulty 1) in fixtures
    # Total difficulty score = 2
    gary = trainers(:gary)
    @gate.required_difficulty_score = 2
    assert @gate.requirement_met_for?(gary)
  end

  test "requirement_met_for? should return true if trainer exceeds difficulty score requirement" do
    # Gary has difficulty score of 2
    gary = trainers(:gary)
    @gate.required_difficulty_score = 1
    assert @gate.requirement_met_for?(gary)
  end

  test "requirement_met_for? should return false if trainer does not meet difficulty score requirement" do
    # Ash has no captured pokemon, difficulty score = 0
    @gate.required_difficulty_score = 100
    assert_not @gate.requirement_met_for?(@trainer)
  end

  # Class Method Tests
  test "gates_data should be loaded from YAML" do
    assert_not_nil Gate.gates_data
    assert_instance_of Array, Gate.gates_data
    assert_equal 9, Gate.gates_data.count
  end

  test "data_for should return gate data for given gate_number" do
    data = Gate.data_for(1)
    assert_not_nil data
    assert_equal "Pewter City Gym - Boulder Badge", data["name"]
    assert_equal 8, data["required_difficulty_score"]
  end

  test "data_for should return nil for non-existent gate_number" do
    data = Gate.data_for(99)
    assert_nil data
  end
end
