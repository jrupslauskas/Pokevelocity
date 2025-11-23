require "test_helper"

class GatesDataTest < ActiveSupport::TestCase
  def setup
    @gates_data = YAML.load_file(Rails.root.join("db", "data", "gates.yml"))
  end

  # Structure and Count Tests
  test "should have exactly 9 gates" do
    assert_equal 9, @gates_data.count,
                 "Expected 9 gates (gate 0 + 8 gym gates), found #{@gates_data.count}"
  end

  test "all gates should have required fields" do
    required_fields = %w[gate_number name description required_difficulty_score sprite_type sprite_value]

    @gates_data.each do |gate|
      missing_fields = required_fields - gate.keys
      assert_empty missing_fields,
                   "Gate '#{gate["name"]}' is missing fields: #{missing_fields.join(', ')}"
    end
  end

  # Gate Number Tests
  test "should have all gate numbers from 0 to 8 with no gaps" do
    gate_numbers = @gates_data.map { |g| g["gate_number"] }.sort
    expected_numbers = (0..8).to_a
    missing_numbers = expected_numbers - gate_numbers

    assert_empty missing_numbers,
                 "Missing gate numbers: #{missing_numbers.join(', ')}"
  end

  test "gate numbers should be unique" do
    gate_numbers = @gates_data.map { |g| g["gate_number"] }
    duplicates = gate_numbers.group_by(&:itself).select { |_, v| v.size > 1 }.keys

    assert_empty duplicates,
                 "Duplicate gate numbers found: #{duplicates.join(', ')}"
  end

  test "gate numbers should be integers" do
    non_integers = @gates_data.reject { |g| g["gate_number"].is_a?(Integer) }

    assert_empty non_integers,
                 "Gates with non-integer gate_number: #{non_integers.map { |g| g["name"] }.join(', ')}"
  end

  # Difficulty Score Tests
  test "required difficulty scores should be positive integers" do
    invalid_scores = @gates_data.select do |gate|
      !gate["required_difficulty_score"].is_a?(Integer) ||
        gate["required_difficulty_score"] < 0
    end

    assert_empty invalid_scores,
                 "Gates with invalid difficulty scores: #{invalid_scores.map { |g| g["name"] }.join(', ')}"
  end

  test "required difficulty scores should be strictly increasing" do
    sorted_gates = @gates_data.sort_by { |g| g["gate_number"] }
    scores = sorted_gates.map { |g| g["required_difficulty_score"] }

    scores.each_cons(2) do |prev_score, next_score|
      assert prev_score < next_score,
             "Difficulty scores must be strictly increasing. Found #{prev_score} followed by #{next_score}"
    end
  end

  test "gate 0 should have the lowest difficulty score" do
    gate_0 = @gates_data.find { |g| g["gate_number"] == 0 }
    other_gates = @gates_data.reject { |g| g["gate_number"] == 0 }

    other_gates.each do |gate|
      assert gate_0["required_difficulty_score"] < gate["required_difficulty_score"],
             "Gate 0 score (#{gate_0["required_difficulty_score"]}) should be less than #{gate["name"]} score (#{gate["required_difficulty_score"]})"
    end
  end

  # Sprite Tests
  test "sprite_type should be either emoji or gym_leader" do
    valid_sprite_types = %w[emoji gym_leader]
    invalid_sprites = @gates_data.reject do |gate|
      valid_sprite_types.include?(gate["sprite_type"])
    end

    assert_empty invalid_sprites,
                 "Gates with invalid sprite_type: #{invalid_sprites.map { |g| "#{g["name"]} (#{g["sprite_type"]})" }.join(', ')}"
  end

  test "gate 0 should use emoji sprite type" do
    gate_0 = @gates_data.find { |g| g["gate_number"] == 0 }

    assert_equal "emoji", gate_0["sprite_type"],
                 "Gate 0 (#{gate_0["name"]}) should use emoji sprite type"
  end

  test "gates 1-8 should use gym_leader sprite type" do
    gym_gates = @gates_data.select { |g| g["gate_number"] >= 1 }
    non_gym_leader_sprites = gym_gates.reject { |g| g["sprite_type"] == "gym_leader" }

    assert_empty non_gym_leader_sprites,
                 "Gym gates should use gym_leader sprite type: #{non_gym_leader_sprites.map { |g| g["name"] }.join(', ')}"
  end

  test "sprite_value should be present for all gates" do
    missing_sprite_value = @gates_data.select do |gate|
      gate["sprite_value"].nil? || gate["sprite_value"].to_s.strip.empty?
    end

    assert_empty missing_sprite_value,
                 "Gates missing sprite_value: #{missing_sprite_value.map { |g| g["name"] }.join(', ')}"
  end

  # Name and Description Tests
  test "all gates should have unique names" do
    names = @gates_data.map { |g| g["name"] }
    duplicates = names.group_by(&:itself).select { |_, v| v.size > 1 }.keys

    assert_empty duplicates,
                 "Duplicate gate names found: #{duplicates.join(', ')}"
  end

  test "all gates should have non-empty names" do
    empty_names = @gates_data.select { |g| g["name"].to_s.strip.empty? }

    assert_empty empty_names,
                 "Gates with empty names at gate numbers: #{empty_names.map { |g| g["gate_number"] }.join(', ')}"
  end

  test "all gates should have non-empty descriptions" do
    empty_descriptions = @gates_data.select { |g| g["description"].to_s.strip.empty? }

    assert_empty empty_descriptions,
                 "Gates with empty descriptions: #{empty_descriptions.map { |g| g["name"] }.join(', ')}"
  end
end
