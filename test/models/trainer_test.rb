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

  test "should have 0 currency by default" do
    trainer = Trainer.create!(
      username: "new_trainer_#{rand(100000)}",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id
    )
    assert_equal 0, trainer.currency
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

  # ================================================================================
  # ADVENTURE MANAGEMENT TESTS
  # ================================================================================

  test "should have adventures_remaining default to 5" do
    trainer = Trainer.create!(
      username: "new_trainer_#{rand(100000)}",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id
    )
    assert_equal 5, trainer.adventures_remaining
  end

  test "available_adventures_to_claim should return 5 when never initialized and trainer has 5 adventures" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 5, adventures_allocated_at: nil)

    # Should be able to claim 5 more (5 + 5 = 10 max)
    assert_equal 5, trainer.available_adventures_to_claim
  end

  test "available_adventures_to_claim should cap at 10 when never initialized" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 8, adventures_allocated_at: nil)

    # Should only be able to claim 2 more (8 + 5 would be 13, capped at 10)
    assert_equal 2, trainer.available_adventures_to_claim
  end

  test "available_adventures_to_claim should return 0 if less than 24 hours have passed" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 2,
      adventures_allocated_at: 12.hours.ago
    )

    assert_equal 0, trainer.available_adventures_to_claim
  end

  test "available_adventures_to_claim should return 5 after 24 hours" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 3,
      adventures_allocated_at: 25.hours.ago
    )

    assert_equal 5, trainer.available_adventures_to_claim
  end

  test "available_adventures_to_claim should respect cap of 10" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 8,
      adventures_allocated_at: 25.hours.ago
    )

    # Would grant 5, but 8 + 5 = 13, so only 2 can be claimed to reach max of 10
    assert_equal 2, trainer.available_adventures_to_claim
  end

  test "available_adventures_to_claim should calculate multiple periods" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 0,
      adventures_allocated_at: 50.hours.ago
    )

    # 50 hours = 2 full periods, so 2 * 5 = 10 adventures
    assert_equal 10, trainer.available_adventures_to_claim
  end

  test "available_adventures_to_claim should return 0 when already at max" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 10,
      adventures_allocated_at: 25.hours.ago
    )

    assert_equal 0, trainer.available_adventures_to_claim
  end

  test "claim_adventures should initialize adventures_allocated_at if nil" do
    trainer = trainers(:ash)
    trainer.update!(adventures_allocated_at: nil)

    result = trainer.claim_adventures

    assert_not_nil trainer.adventures_allocated_at
    assert_equal 10, trainer.adventures_remaining
    assert_equal 5, result[:claimed]
    assert_equal 10, result[:new_total]
  end

  test "claim_adventures should add 5 adventures for new user starting with 5" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 5, adventures_allocated_at: nil)

    result = trainer.claim_adventures

    assert_not_nil trainer.adventures_allocated_at
    assert_equal 10, trainer.adventures_remaining
    assert_equal 5, result[:claimed]
    assert_equal 10, result[:new_total]
  end

  test "claim_adventures should add 5 adventures for user with 4 adventures" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 4, adventures_allocated_at: nil)

    result = trainer.claim_adventures

    assert_not_nil trainer.adventures_allocated_at
    assert_equal 9, trainer.adventures_remaining
    assert_equal 5, result[:claimed]
    assert_equal 9, result[:new_total]
  end

  test "claim_adventures should cap at 10 for user with 7 adventures claiming first time" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 7, adventures_allocated_at: nil)

    result = trainer.claim_adventures

    assert_not_nil trainer.adventures_allocated_at
    assert_equal 10, trainer.adventures_remaining
    assert_equal 3, result[:claimed]
    assert_equal 10, result[:new_total]
  end

  test "claim_adventures should not replenish if less than 24 hours have passed" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 2,
      adventures_allocated_at: 12.hours.ago
    )

    result = trainer.claim_adventures

    assert_equal 2, trainer.adventures_remaining
    assert_equal 0, result[:claimed]
    assert_equal 2, result[:new_total]
    assert_in_delta 12.hours.ago.to_i, trainer.adventures_allocated_at.to_i, 5
  end

  test "claim_adventures should add 5 adventures after 24 hours" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 3,
      adventures_allocated_at: 25.hours.ago
    )

    result = trainer.claim_adventures

    assert_equal 8, trainer.adventures_remaining
    assert_equal 5, result[:claimed]
    assert_equal 8, result[:new_total]
  end

  test "claim_adventures should cap at 10 adventures" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 8,
      adventures_allocated_at: 25.hours.ago
    )

    result = trainer.claim_adventures

    # Should be 8 + 5 = 13, but capped at 10
    assert_equal 10, trainer.adventures_remaining
    assert_equal 2, result[:claimed]
    assert_equal 10, result[:new_total]
  end

  test "claim_adventures should grant multiple periods worth of adventures" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 0,
      adventures_allocated_at: 50.hours.ago
    )

    result = trainer.claim_adventures

    # 50 hours = 2 full periods, so 0 + 5 + 5 = 10
    assert_equal 10, trainer.adventures_remaining
    assert_equal 10, result[:claimed]
    assert_equal 10, result[:new_total]
  end

  test "claim_adventures should advance timestamp by full periods only" do
    trainer = trainers(:ash)
    allocation_time = 50.hours.ago
    trainer.update!(
      adventures_remaining: 2,
      adventures_allocated_at: allocation_time
    )

    result = trainer.claim_adventures

    # Should advance by 48 hours (2 full periods), leaving 2 hours remaining
    # Starting with 2, adding 2 periods (10 adventures) should reach cap of 10
    expected_time = allocation_time + 48.hours
    assert_in_delta expected_time.to_i, trainer.adventures_allocated_at.to_i, 5
    assert_equal 8, result[:claimed]  # Can only add 8 to reach cap of 10
    assert_equal 10, result[:new_total]
  end

  test "claim_adventures should not replenish when already at 10" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 10,
      adventures_allocated_at: 25.hours.ago
    )

    result = trainer.claim_adventures

    assert_equal 10, trainer.adventures_remaining
    assert_equal 0, result[:claimed]
    assert_equal 10, result[:new_total]
  end

  test "claim_adventures should not advance timestamp when at max" do
    trainer = trainers(:ash)
    allocation_time = 50.hours.ago
    trainer.update!(
      adventures_remaining: 10,
      adventures_allocated_at: allocation_time
    )

    result = trainer.claim_adventures

    # When already at max, no claiming happens and timestamp stays the same
    assert_equal allocation_time.to_i, trainer.adventures_allocated_at.to_i
    assert_equal 10, trainer.adventures_remaining
    assert_equal 0, result[:claimed]
    assert_equal 10, result[:new_total]
  end

  test "claim_adventures with 3 adventures after 24h should have 8" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 3,
      adventures_allocated_at: 24.hours.ago
    )

    result = trainer.claim_adventures

    assert_equal 8, trainer.adventures_remaining
    assert_equal 5, result[:claimed]
    assert_equal 8, result[:new_total]
  end

  test "claim_adventures with 8 adventures after 24h should have 10" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 8,
      adventures_allocated_at: 24.hours.ago
    )

    result = trainer.claim_adventures

    # 8 + 5 = 13, capped at 10
    assert_equal 10, trainer.adventures_remaining
    assert_equal 2, result[:claimed]
    assert_equal 10, result[:new_total]
  end

  test "claim_adventures with 7 adventures after 24h should cap at 10" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 7,
      adventures_allocated_at: 24.hours.ago
    )

    result = trainer.claim_adventures

    # 7 + 5 = 12, but capped at 10
    assert_equal 10, trainer.adventures_remaining
    assert_equal 3, result[:claimed]  # Only grants +3 to reach cap
    assert_equal 10, result[:new_total]
  end

  test "claim_adventures with 0 adventures after 72h should cap at 10" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 0,
      adventures_allocated_at: 72.hours.ago
    )

    result = trainer.claim_adventures

    # 3 periods = 15 adventures, but capped at 10
    assert_equal 10, trainer.adventures_remaining
    assert_equal 10, result[:claimed]
    assert_equal 10, result[:new_total]
  end

  test "has_adventures? should return true when adventures_remaining > 0" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 3)

    assert trainer.has_adventures?
  end

  test "has_adventures? should return false when adventures_remaining is 0" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 0)

    assert_not trainer.has_adventures?
  end

  test "use_adventure should decrement adventures_remaining by 1" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 3)

    result = trainer.use_adventure

    assert result
    assert_equal 2, trainer.reload.adventures_remaining
  end

  test "use_adventure should return false when no adventures remaining" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 0)

    result = trainer.use_adventure

    assert_not result
    assert_equal 0, trainer.reload.adventures_remaining
  end

  test "use_adventure should work when adventures_remaining is 1" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 1)

    result = trainer.use_adventure

    assert result
    assert_equal 0, trainer.reload.adventures_remaining
  end

  test "time_until_next_adventure should return 0 if allocated_at is nil" do
    trainer = trainers(:ash)
    trainer.update!(adventures_allocated_at: nil)

    assert_equal 0, trainer.time_until_next_adventure
  end

  test "time_until_next_adventure should return positive seconds remaining" do
    trainer = trainers(:ash)
    trainer.update!(adventures_allocated_at: 20.hours.ago)

    # Should have about 4 hours (14400 seconds) remaining
    time_remaining = trainer.time_until_next_adventure

    assert time_remaining > 0
    assert_in_delta 4.hours.to_i, time_remaining, 60 # Within 1 minute tolerance
  end

  test "time_until_next_adventure should return 0 if refresh time has passed" do
    trainer = trainers(:ash)
    trainer.update!(adventures_allocated_at: 25.hours.ago)

    assert_equal 0, trainer.time_until_next_adventure
  end

  test "formatted_time_until_adventure should return 'now' when 0 seconds remaining" do
    trainer = trainers(:ash)
    trainer.update!(adventures_allocated_at: 25.hours.ago)

    assert_equal "now", trainer.formatted_time_until_adventure
  end

  test "formatted_time_until_adventure should format hours and minutes" do
    trainer = trainers(:ash)
    # 5 hours and 30 minutes ago means 18.5 hours remaining
    trainer.update!(adventures_allocated_at: 5.5.hours.ago)

    formatted = trainer.formatted_time_until_adventure

    # Should be something like "18h 30m"
    assert_match /\d+h \d+m/, formatted
  end

  test "formatted_time_until_adventure should format minutes only when less than 1 hour" do
    trainer = trainers(:ash)
    # 23 hours and 30 minutes ago means 30 minutes remaining
    trainer.update!(adventures_allocated_at: 23.5.hours.ago)

    formatted = trainer.formatted_time_until_adventure

    # Should be something like "30m"
    assert_match /\d+m/, formatted
    assert_no_match /h/, formatted
  end

  test "formatted_time_until_adventure should format seconds only when less than 1 minute" do
    trainer = trainers(:ash)
    # 23 hours, 59 minutes, 45 seconds ago means 15 seconds remaining
    trainer.update!(adventures_allocated_at: (24.hours - 15.seconds).ago)

    formatted = trainer.formatted_time_until_adventure

    # Should be something like "15s"
    assert_match /\d+s/, formatted
    assert_no_match /h|m/, formatted
  end

  # ================================================================================
  # USE POTION TESTS
  # ================================================================================

  test "use_potion should restore adventures and consume potion" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 5, adventures_allocated_at: 1.hour.ago)
    trainer.add_item(:potion, 1)

    result = trainer.use_potion(:potion)

    assert result[:success]
    assert_equal 3, result[:restored]
    assert_equal 8, result[:new_total]
    assert_equal "Potion", result[:potion_name]
    assert_equal 8, trainer.reload.adventures_remaining
    assert_equal 0, trainer.item_quantity(:potion)
  end

  test "use_potion should cap adventures at 10" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 8, adventures_allocated_at: 1.hour.ago)
    trainer.add_item(:super_potion, 1)

    result = trainer.use_potion(:super_potion)

    assert result[:success]
    assert_equal 2, result[:restored]  # 8 + 6 = 14, but capped at 10, so only +2
    assert_equal 10, result[:new_total]
    assert_equal 10, trainer.reload.adventures_remaining
    assert_equal 0, trainer.item_quantity(:super_potion)
  end

  test "use_potion should fail when trainer doesn't have potion" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 5)

    result = trainer.use_potion(:potion)

    assert_not result[:success]
    assert_equal "You don't have any Potion", result[:error]
    assert_equal 5, trainer.reload.adventures_remaining
  end

  test "use_potion should fail when already at max adventures" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 10, adventures_allocated_at: 1.hour.ago)
    trainer.add_item(:potion, 1)

    result = trainer.use_potion(:potion)

    assert_not result[:success]
    assert_equal "You already have maximum adventures", result[:error]
    assert_equal 10, trainer.reload.adventures_remaining
    assert_equal 1, trainer.item_quantity(:potion)  # Potion should not be consumed
  end

  test "use_potion should work with super_potion" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 3, adventures_allocated_at: 1.hour.ago)
    trainer.add_item(:super_potion, 1)

    result = trainer.use_potion(:super_potion)

    assert result[:success]
    assert_equal 6, result[:restored]
    assert_equal 9, result[:new_total]
    assert_equal "Super Potion", result[:potion_name]
    assert_equal 9, trainer.reload.adventures_remaining
    assert_equal 0, trainer.item_quantity(:super_potion)
  end

  test "use_potion should work with hyper_potion" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 0, adventures_allocated_at: 1.hour.ago)
    trainer.add_item(:hyper_potion, 1)

    result = trainer.use_potion(:hyper_potion)

    assert result[:success]
    assert_equal 10, result[:restored]
    assert_equal 10, result[:new_total]
    assert_equal "Hyper Potion", result[:potion_name]
    assert_equal 10, trainer.reload.adventures_remaining
    assert_equal 0, trainer.item_quantity(:hyper_potion)
  end

  test "use_potion should fail with non-existent item" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 5)

    result = trainer.use_potion(:nonexistent_item)

    assert_not result[:success]
    assert_equal "Item not found", result[:error]
    assert_equal 5, trainer.reload.adventures_remaining
  end

  test "use_potion should fail with non-potion item" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 5)

    result = trainer.use_potion(:fire_stone)

    assert_not result[:success]
    assert_equal "This item is not a potion", result[:error]
    assert_equal 5, trainer.reload.adventures_remaining
  end

  test "use_potion should initialize adventures_allocated_at if nil" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 5, adventures_allocated_at: nil)
    trainer.add_item(:potion, 1)

    result = trainer.use_potion(:potion)

    assert result[:success]
    assert_not_nil trainer.reload.adventures_allocated_at
  end

  test "use_potion should consume only one potion when multiple are owned" do
    trainer = trainers(:ash)
    trainer.update!(adventures_remaining: 5, adventures_allocated_at: 1.hour.ago)
    trainer.add_item(:potion, 3)

    result = trainer.use_potion(:potion)

    assert result[:success]
    assert_equal 2, trainer.item_quantity(:potion)  # Should have 2 left
  end
end
