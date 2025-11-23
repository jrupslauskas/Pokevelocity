require "test_helper"

class GateUnlockTest < ActiveSupport::TestCase
  def setup
    @trainer = trainers(:ash)
    @gate = Gate.create!(
      gate_number: 5,
      name: "Test Gate",
      required_difficulty_score: 100,
      sprite_type: "gym_leader",
      sprite_value: "test"
    )
    @gate_unlock = GateUnlock.new(trainer: @trainer, gate: @gate)
  end

  # Validation Tests
  test "should be valid with valid attributes" do
    assert @gate_unlock.valid?
  end

  test "should require trainer" do
    @gate_unlock.trainer = nil
    assert_not @gate_unlock.valid?
    assert_includes @gate_unlock.errors[:trainer], "must exist"
  end

  test "should require gate" do
    @gate_unlock.gate = nil
    assert_not @gate_unlock.valid?
    assert_includes @gate_unlock.errors[:gate], "must exist"
  end

  test "should validate presence of unlocked_at after callback" do
    # The before_validation callback should always set unlocked_at
    # So after validation, it should never be nil
    assert @gate_unlock.valid?
    assert_not_nil @gate_unlock.unlocked_at
  end

  test "should not allow duplicate trainer and gate combination" do
    @gate_unlock.save!

    duplicate_unlock = GateUnlock.new(trainer: @trainer, gate: @gate, unlocked_at: Time.current)
    assert_not duplicate_unlock.valid?
    assert_includes duplicate_unlock.errors[:trainer_id], "has already unlocked this gate"
  end

  test "should allow same gate to be unlocked by different trainers" do
    @gate_unlock.save!

    other_trainer = trainers(:gary)
    other_unlock = GateUnlock.new(trainer: other_trainer, gate: @gate, unlocked_at: Time.current)
    assert other_unlock.valid?
  end

  test "should allow same trainer to unlock different gates" do
    @gate_unlock.save!

    other_gate = Gate.create!(
      gate_number: 6,
      name: "Another Test Gate",
      required_difficulty_score: 150,
      sprite_type: "gym_leader",
      sprite_value: "test2"
    )
    other_unlock = GateUnlock.new(trainer: @trainer, gate: other_gate, unlocked_at: Time.current)
    assert other_unlock.valid?
  end

  # Association Tests
  test "should belong to trainer" do
    assert_respond_to @gate_unlock, :trainer
    assert_instance_of Trainer, @gate_unlock.trainer
  end

  test "should belong to gate" do
    assert_respond_to @gate_unlock, :gate
    assert_instance_of Gate, @gate_unlock.gate
  end

  # Callback Tests
  test "should automatically set unlocked_at on creation if not provided" do
    unlock = GateUnlock.create!(trainer: @trainer, gate: @gate)
    assert_not_nil unlock.unlocked_at
    assert_in_delta Time.current, unlock.unlocked_at, 2.seconds
  end

  test "should not override unlocked_at if provided" do
    custom_time = 1.week.ago
    unlock = GateUnlock.create!(trainer: @trainer, gate: @gate, unlocked_at: custom_time)
    assert_equal custom_time.to_i, unlock.unlocked_at.to_i
  end

  test "set_unlocked_at should only run on creation" do
    @gate_unlock.save!
    original_time = @gate_unlock.unlocked_at

    # Update the record without changing unlocked_at
    @gate_unlock.update!(unlocked_at: 1.week.ago)

    # The callback shouldn't reset it to Time.current
    assert_not_equal Time.current.to_i, @gate_unlock.unlocked_at.to_i
  end
end
