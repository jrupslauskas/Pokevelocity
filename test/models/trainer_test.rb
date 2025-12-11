require "test_helper"

class TrainerTest < ActiveSupport::TestCase
  # ================================================================================
  # VALIDATION TESTS
  # ================================================================================

  test "should be valid with valid attributes" do
    trainer = Trainer.new(
      username: "test_trainer",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id
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

  test "should allow nil icon pokemon on update" do
    trainer = Trainer.new(username: "test", password: "password", icon_pokemon_id: pokemons(:pikachu).id)
    assert trainer.valid?
    # Can update without icon (validation only on create)
    trainer.save!
    trainer.icon_pokemon_id = nil
    assert trainer.valid?
    assert_nil trainer.icon_pokemon
  end

  # ================================================================================
  # BALL COUNTING TESTS
  # ================================================================================

  test "should calculate total pokeballs correctly" do
    trainer = trainers(:ash)
    # ash has 5 pokeballs + 3 great balls + 2 ultra balls + 1 master ball = 11 total
    assert_equal 11, trainer.total_pokeballs
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

  test "ball_count should return correct count for each ball type" do
    trainer = trainers(:ash)
    assert_equal 5, trainer.ball_count(:pokeball)
    assert_equal 3, trainer.ball_count(:great_ball)
    assert_equal 2, trainer.ball_count(:ultra_ball)
    assert_equal 1, trainer.ball_count(:master_ball)
  end

  test "has_ball? should return true when trainer has balls" do
    trainer = trainers(:ash)
    assert trainer.has_ball?(:pokeball)
    assert trainer.has_ball?(:great_ball)
    assert trainer.has_ball?(:ultra_ball)
    assert trainer.has_ball?(:master_ball)
  end

  test "has_ball? should return false when trainer has no balls" do
    trainer = trainers(:broke_trainer)
    assert_not trainer.has_ball?(:pokeball)
    assert_not trainer.has_ball?(:great_ball)
    assert_not trainer.has_ball?(:ultra_ball)
    assert_not trainer.has_ball?(:master_ball)
  end

  test "deduct_ball! should decrease ball count" do
    trainer = trainers(:ash)
    initial_count = trainer.ball_count(:pokeball)
    trainer.deduct_ball!(:pokeball)
    assert_equal initial_count - 1, trainer.ball_count(:pokeball)
  end

  test "add_ball! should increase ball count" do
    trainer = trainers(:ash)
    initial_count = trainer.ball_count(:pokeball)
    trainer.add_ball!(:pokeball)
    assert_equal initial_count + 1, trainer.ball_count(:pokeball)
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
    trainer = Trainer.new(username: "test", password: "secret", icon_pokemon_id: pokemons(:pikachu).id)
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

  # ================================================================================
  # ITEM MANAGEMENT TESTS
  # ================================================================================

  test "should have many trainer_items" do
    association = Trainer.reflect_on_association(:trainer_items)
    assert_equal :has_many, association.macro
  end

  test "should have many items through trainer_items" do
    association = Trainer.reflect_on_association(:items)
    assert_equal :has_many, association.macro
    assert_equal :trainer_items, association.options[:through]
  end

  test "item_quantity should return 0 for item trainer doesn't have" do
    trainer = trainers(:broke_trainer) # broke_trainer has no items
    assert_equal 0, trainer.item_quantity(:fire_stone)
  end

  test "item_quantity should return correct quantity for owned item" do
    trainer = trainers(:ash)
    # ash already has pokeballs from fixtures, let's add a stone
    item = items(:fire_stone)
    TrainerItem.create!(trainer: trainer, item: item, quantity: 5)

    assert_equal 5, trainer.item_quantity(:fire_stone)
  end

  test "add_item should create new trainer_item if not exists" do
    trainer = trainers(:broke_trainer) # broke_trainer has no items

    result = trainer.add_item(:water_stone, 3)

    assert result
    assert_equal 3, trainer.item_quantity(:water_stone)
  end

  test "add_item should increment existing trainer_item quantity" do
    trainer = trainers(:broke_trainer)
    # First add some thunder stones
    trainer.add_item(:thunder_stone, 2)

    # Then add more
    trainer.add_item(:thunder_stone, 3)

    assert_equal 5, trainer.item_quantity(:thunder_stone)
  end

  test "add_item should default to adding 1" do
    trainer = trainers(:broke_trainer)

    trainer.add_item(:water_stone)

    assert_equal 1, trainer.item_quantity(:water_stone)
  end

  test "add_item should return false for non-existent item" do
    trainer = trainers(:ash)
    result = trainer.add_item(:nonexistent_item)

    assert_not result
  end

  test "remove_item should decrement item quantity" do
    trainer = trainers(:broke_trainer)
    # First add some fire stones
    trainer.add_item(:fire_stone, 5)

    result = trainer.remove_item(:fire_stone, 2)

    assert result
    assert_equal 3, trainer.item_quantity(:fire_stone)
  end

  test "remove_item should default to removing 1" do
    trainer = trainers(:broke_trainer)
    # First add some fire stones
    trainer.add_item(:fire_stone, 3)

    trainer.remove_item(:fire_stone)

    assert_equal 2, trainer.item_quantity(:fire_stone)
  end

  test "remove_item should return false if not enough items" do
    trainer = trainers(:broke_trainer)
    # First add some water stones
    trainer.add_item(:water_stone, 2)

    result = trainer.remove_item(:water_stone, 5)

    assert_not result
    assert_equal 2, trainer.item_quantity(:water_stone)
  end

  test "remove_item should return false if item doesn't exist" do
    trainer = trainers(:broke_trainer)
    result = trainer.remove_item(:nonexistent_item)

    assert_not result
  end

  test "has_item? should return true if trainer has enough quantity" do
    trainer = trainers(:broke_trainer)
    # First add some thunder stones
    trainer.add_item(:thunder_stone, 5)

    assert trainer.has_item?(:thunder_stone, 3)
    assert trainer.has_item?(:thunder_stone, 5)
  end

  test "has_item? should return false if trainer doesn't have enough quantity" do
    trainer = trainers(:broke_trainer)
    # First add some water stones
    trainer.add_item(:water_stone, 2)

    assert_not trainer.has_item?(:water_stone, 5)
  end

  test "has_item? should default to checking for quantity of 1" do
    trainer = trainers(:broke_trainer)
    # First add a fire stone
    trainer.add_item(:fire_stone, 1)

    assert trainer.has_item?(:fire_stone)
  end

  test "has_item? should return false if trainer doesn't have item at all" do
    trainer = trainers(:broke_trainer)
    assert_not trainer.has_item?(:fire_stone)
  end
end
