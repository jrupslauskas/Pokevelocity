require "test_helper"

class TrainerTest < ActiveSupport::TestCase
  # ================================================================================
  # VALIDATION TESTS
  # ================================================================================

  test "should be valid with valid attributes" do
    trainer = Trainer.new(
      username: "test_trainer",
      password: "password",
      pokeballs_count: 0,
      great_balls_count: 0,
      ultra_balls_count: 0,
      master_balls_count: 0
    )
    assert trainer.valid?
  end

  test "should require username" do
    trainer = Trainer.new(password: "password")
    assert_not trainer.valid?
    assert_includes trainer.errors[:username], "can't be blank"
  end

  test "should require unique username" do
    existing = trainers(:ash)
    trainer = Trainer.new(username: existing.username, password: "password")
    assert_not trainer.valid?
    assert_includes trainer.errors[:username], "has already been taken"
  end

  test "should require password on create" do
    trainer = Trainer.new(username: "new_trainer")
    assert_not trainer.valid?
    assert_includes trainer.errors[:password], "can't be blank"
  end

  test "should require non-negative ball counts" do
    trainer = trainers(:ash)

    trainer.pokeballs_count = -1
    assert_not trainer.valid?

    trainer.pokeballs_count = 0
    trainer.great_balls_count = -1
    assert_not trainer.valid?

    trainer.great_balls_count = 0
    trainer.ultra_balls_count = -1
    assert_not trainer.valid?

    trainer.ultra_balls_count = 0
    trainer.master_balls_count = -1
    assert_not trainer.valid?
  end

  # ================================================================================
  # ASSOCIATION TESTS
  # ================================================================================

  test "should have many captures" do
    trainer = trainers(:gary)
    assert_equal 2, trainer.captures.count
  end

  test "should have many captured pokemon through captures" do
    trainer = trainers(:gary)
    assert_equal 2, trainer.captured_pokemon.count
    assert_includes trainer.captured_pokemon, pokemons(:charmander)
    assert_includes trainer.captured_pokemon, pokemons(:squirtle)
  end

  test "should belong to icon pokemon" do
    trainer = trainers(:ash)
    assert_equal pokemons(:pikachu), trainer.icon_pokemon
  end

  test "should allow nil icon pokemon" do
    trainer = Trainer.new(username: "test", password: "password")
    assert_nil trainer.icon_pokemon
    assert trainer.valid?
  end

  # ================================================================================
  # BALL COUNTING TESTS
  # ================================================================================

  test "should calculate total pokeballs correctly" do
    trainer = trainers(:ash)
    expected_total = trainer.pokeballs_count + trainer.great_balls_count +
                     trainer.ultra_balls_count + trainer.master_balls_count
    assert_equal expected_total, trainer.total_pokeballs
  end

  test "should return zero total pokeballs when trainer has no balls" do
    trainer = trainers(:broke_trainer)
    assert_equal 0, trainer.total_pokeballs
  end

  test "should return correct total pokeballs with mixed ball types" do
    trainer = trainers(:ash)
    # ash has 5 pokeballs, 3 great balls, 2 ultra balls, 1 master ball
    assert_equal 11, trainer.total_pokeballs
  end

  # ================================================================================
  # REWARD SERVICE INTEGRATION TESTS
  # ================================================================================

  test "should award pokeball for ticket via service" do
    trainer = trainers(:ash)
    initial_total = trainer.total_pokeballs

    result = trainer.award_pokeball_for_ticket(1)

    assert_not_nil result
    assert_not_nil result[:ball_type]

    trainer.reload
    assert_equal initial_total + 1, trainer.total_pokeballs
  end

  test "should call PokeballRewardService when awarding pokeball for ticket" do
    trainer = trainers(:ash)
    initial_total = trainer.total_pokeballs

    # Call the method that should delegate to the service
    result = trainer.award_pokeball_for_ticket(1)

    # Verify it returned a result (which means service was called)
    assert_not_nil result
    assert result.is_a?(Hash)
    assert_includes result.keys, :ball_type

    # Verify the trainer's balls were actually updated
    trainer.reload
    assert_equal initial_total + 1, trainer.total_pokeballs
  end

  # ================================================================================
  # PASSWORD TESTS
  # ================================================================================

  test "should authenticate with correct password" do
    trainer = trainers(:ash)
    assert trainer.authenticate("password")
  end

  test "should not authenticate with incorrect password" do
    trainer = trainers(:ash)
    assert_not trainer.authenticate("wrong_password")
  end

  test "should hash password on save" do
    trainer = Trainer.new(username: "test", password: "secret")
    trainer.save!

    assert_not_nil trainer.password_digest
    assert_not_equal "secret", trainer.password_digest
  end

  # ================================================================================
  # LEADERBOARD SCORE TESTS
  # ================================================================================

  test "should calculate difficulty score as sum of captured pokemon difficulties" do
    trainer = trainers(:gary)
    # Gary has caught charmander (difficulty 1) and squirtle (difficulty 1)
    expected_score = trainer.captured_pokemon.sum(:difficulty)

    assert_equal expected_score, trainer.difficulty_score
    assert_equal 2, trainer.difficulty_score
  end

  test "should return zero difficulty score when no pokemon caught" do
    trainer = trainers(:broke_trainer)
    assert_equal 0, trainer.difficulty_score
  end

  test "should return leaderboard score hash with all required data" do
    trainer = trainers(:gary)
    score = trainer.leaderboard_score

    assert_not_nil score
    assert_equal trainer, score[:trainer]
    assert_equal 2, score[:pokemon_count]
    assert_equal 2, score[:difficulty_score]
  end
end
