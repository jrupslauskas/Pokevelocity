require "test_helper"

class ValidationCodeTest < ActiveSupport::TestCase
  # ================================================================================
  # VALID MODEL TESTS
  # ================================================================================

  test "should save valid validation code" do
    validation_code = ValidationCode.new(code: "ABC123", active: true)
    assert validation_code.save
  end

  test "should have active field default to true" do
    validation_code = ValidationCode.create(code: "DEF456")
    assert validation_code.active
  end

  test "should allow inactive validation codes" do
    validation_code = ValidationCode.new(code: "GHI789", active: false)
    assert validation_code.save
  end

  # ================================================================================
  # CODE PRESENCE VALIDATION TESTS
  # ================================================================================

  test "should require code to be present" do
    validation_code = ValidationCode.new(code: nil, active: true)
    assert_not validation_code.save
  end

  test "should add error when code is nil" do
    validation_code = ValidationCode.new(code: nil, active: true)
    validation_code.save
    assert_includes validation_code.errors[:code], "can't be blank"
  end

  test "should not save with empty code" do
    validation_code = ValidationCode.new(code: "", active: true)
    assert_not validation_code.save
  end

  test "should add error when code is empty" do
    validation_code = ValidationCode.new(code: "", active: true)
    validation_code.save
    assert validation_code.errors[:code].any?
  end

  # ================================================================================
  # CODE LENGTH VALIDATION TESTS
  # ================================================================================

  test "should require code to be exactly 6 characters" do
    validation_code = ValidationCode.new(code: "ABC12", active: true)
    assert_not validation_code.save
  end

  test "should add error when code is too short" do
    validation_code = ValidationCode.new(code: "ABC", active: true)
    validation_code.save
    assert_includes validation_code.errors[:code], "is the wrong length (should be 6 characters)"
  end

  test "should add error when code is too long" do
    validation_code = ValidationCode.new(code: "ABCDEFG", active: true)
    validation_code.save
    assert_includes validation_code.errors[:code], "is the wrong length (should be 6 characters)"
  end

  test "should save code with exactly 6 characters" do
    validation_code = ValidationCode.new(code: "XYZ123", active: true)
    assert validation_code.save
  end

  test "should accept code with 6 letters" do
    validation_code = ValidationCode.new(code: "ABCDEF", active: true)
    assert validation_code.save
  end

  test "should accept code with 6 numbers" do
    validation_code = ValidationCode.new(code: "123456", active: true)
    assert validation_code.save
  end

  test "should accept code with mixed alphanumeric characters" do
    validation_code = ValidationCode.new(code: "A1B2C3", active: true)
    assert validation_code.save
  end

  # ================================================================================
  # CODE UNIQUENESS VALIDATION TESTS
  # ================================================================================

  test "should require unique code" do
    existing_code = validation_codes(:active_code)
    duplicate_code = ValidationCode.new(code: existing_code.code, active: true)
    assert_not duplicate_code.save
  end

  test "should add error when code is not unique" do
    existing_code = validation_codes(:active_code)
    duplicate_code = ValidationCode.new(code: existing_code.code, active: true)
    duplicate_code.save
    assert_includes duplicate_code.errors[:code], "has already been taken"
  end

  test "should allow same code after deletion" do
    existing_code = validation_codes(:active_code)
    code_string = existing_code.code
    existing_code.destroy

    new_code = ValidationCode.new(code: code_string, active: true)
    assert new_code.save
  end

  test "should enforce uniqueness case sensitively" do
    ValidationCode.create(code: "UPPER1", active: true)
    lowercase_version = ValidationCode.new(code: "upper1", active: true)
    # Rails default uniqueness validation is case-insensitive in database
    # but we test the actual behavior
    assert lowercase_version.save
  end

  # ================================================================================
  # ACTIVE FIELD TESTS
  # ================================================================================

  test "should allow querying active codes" do
    active_codes = ValidationCode.where(active: true)
    assert_includes active_codes, validation_codes(:active_code)
    assert_not_includes active_codes, validation_codes(:inactive_code)
  end

  test "should allow querying inactive codes" do
    inactive_codes = ValidationCode.where(active: false)
    assert_includes inactive_codes, validation_codes(:inactive_code)
    assert_not_includes inactive_codes, validation_codes(:active_code)
  end

  test "should toggle active status" do
    code = validation_codes(:active_code)
    assert code.active

    code.update(active: false)
    assert_not code.active
  end

  # ================================================================================
  # FIXTURE VALIDATION TESTS
  # ================================================================================

  test "should load active_code fixture" do
    code = validation_codes(:active_code)
    assert code.valid?
    assert_equal "TEST01", code.code
    assert code.active
  end

  test "should load inactive_code fixture" do
    code = validation_codes(:inactive_code)
    assert code.valid?
    assert_equal "TEST02", code.code
    assert_not code.active
  end

  # ================================================================================
  # EDGE CASE TESTS
  # ================================================================================

  test "should accept code with special characters if 6 chars" do
    validation_code = ValidationCode.new(code: "!@#$%^", active: true)
    assert validation_code.save
  end

  test "should accept code with spaces if 6 chars" do
    validation_code = ValidationCode.new(code: "AB CD ", active: true)
    assert validation_code.save
  end

  test "should handle code update" do
    code = validation_codes(:active_code)
    code.update(code: "NEW123")
    assert code.valid?
    assert_equal "NEW123", code.code
  end

  test "should not allow updating to duplicate code" do
    code1 = validation_codes(:active_code)
    code2 = validation_codes(:inactive_code)

    code2.code = code1.code
    assert_not code2.save
  end
end
