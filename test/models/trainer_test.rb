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

  test "should have high_contrast_mode false by default" do
    trainer = Trainer.create!(
      username: "new_trainer_#{rand(100000)}",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id
    )
    assert_equal false, trainer.high_contrast_mode
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

  test "should have pokecenter_credits default to 0" do
    trainer = Trainer.create!(
      username: "new_trainer_#{rand(100000)}",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id
    )
    assert_equal 0, trainer.pokecenter_credits
  end

  # ================================================================================
  # POKECENTER CREDIT TESTS
  # ================================================================================

  test "available_pokecenter_credits should return 1 for first time visitor" do
    trainer = trainers(:ash)
    trainer.update!(pokecenter_credits: 0, adventures_allocated_at: nil)

    assert_equal 1, trainer.available_pokecenter_credits
  end

  test "available_pokecenter_credits should use banked credits if visited same day" do
    trainer = trainers(:ash)
    trainer.update!(
      pokecenter_credits: 1,
      adventures_allocated_at: 12.hours.ago # Still today
    )

    # Should have the 1 banked credit, no new credits added
    assert_equal 1, trainer.available_pokecenter_credits
  end

  test "available_pokecenter_credits should return 0 when no banked credits and visited same day" do
    trainer = trainers(:ash)
    trainer.update!(
      pokecenter_credits: 0,
      adventures_allocated_at: 12.hours.ago # Still today
    )

    assert_equal 0, trainer.available_pokecenter_credits
  end

  test "available_pokecenter_credits should add 1 credit after 1 day" do
    trainer = trainers(:ash)
    trainer.update!(
      pokecenter_credits: 0,
      adventures_allocated_at: 1.day.ago
    )

    assert_equal 1, trainer.available_pokecenter_credits
  end

  test "available_pokecenter_credits should add credits up to max of 2" do
    trainer = trainers(:ash)
    trainer.update!(
      pokecenter_credits: 0,
      adventures_allocated_at: 2.days.ago
    )

    # 0 banked + 2 days elapsed = 2 credits (capped)
    assert_equal 2, trainer.available_pokecenter_credits
  end

  test "available_pokecenter_credits should cap at 2 even after many days" do
    trainer = trainers(:ash)
    trainer.update!(
      pokecenter_credits: 0,
      adventures_allocated_at: 5.days.ago
    )

    # 0 banked + 5 days = would be 5, but capped at 2
    assert_equal 2, trainer.available_pokecenter_credits
  end

  test "available_pokecenter_credits should remain at 2 when already at max" do
    trainer = trainers(:ash)
    trainer.update!(
      pokecenter_credits: 2,
      adventures_allocated_at: 3.days.ago
    )

    # Already at max, should stay at 2
    assert_equal 2, trainer.available_pokecenter_credits
  end

  test "available_pokecenter_credits should add to existing banked credits" do
    trainer = trainers(:ash)
    trainer.update!(
      pokecenter_credits: 1,
      adventures_allocated_at: 1.day.ago
    )

    # 1 banked + 1 day elapsed = 2 credits
    assert_equal 2, trainer.available_pokecenter_credits
  end

  test "available_pokecenter_credits should not exceed 2 when adding to banked credits" do
    trainer = trainers(:ash)
    trainer.update!(
      pokecenter_credits: 1,
      adventures_allocated_at: 3.days.ago
    )

    # 1 banked + 3 days = would be 4, but capped at 2
    assert_equal 2, trainer.available_pokecenter_credits
  end

  # ================================================================================
  # CLAIM ADVENTURES (VISIT POKECENTER) TESTS
  # ================================================================================

  test "claim_adventures should work for first time visitor" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 5,
      pokecenter_credits: 0,
      adventures_allocated_at: nil
    )

    result = trainer.claim_adventures

    assert result[:success]
    assert_equal 5, result[:restored]
    assert_equal 10, result[:new_total]
    assert_equal 0, result[:credits_remaining]
    assert_equal 10, trainer.reload.adventures_remaining
    assert_equal 0, trainer.pokecenter_credits
    assert_not_nil trainer.adventures_allocated_at
  end

  test "claim_adventures should fail when no credits available" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 5,
      pokecenter_credits: 0,
      adventures_allocated_at: 12.hours.ago # Same day
    )

    result = trainer.claim_adventures

    assert_not result[:success]
    assert_equal 0, result[:restored]
    assert_equal 5, result[:new_total]
    assert_equal 0, result[:credits_remaining]
    assert_equal 5, trainer.reload.adventures_remaining
  end

  test "claim_adventures should use 1 credit and restore 5 adventures" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 3,
      pokecenter_credits: 0,
      adventures_allocated_at: 1.day.ago
    )

    result = trainer.claim_adventures

    assert result[:success]
    assert_equal 5, result[:restored]
    assert_equal 8, result[:new_total]
    assert_equal 0, result[:credits_remaining]
    assert_equal 8, trainer.reload.adventures_remaining
    assert_equal 0, trainer.pokecenter_credits
  end

  test "claim_adventures should cap adventures at 10" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 8,
      pokecenter_credits: 0,
      adventures_allocated_at: 1.day.ago
    )

    result = trainer.claim_adventures

    assert result[:success]
    assert_equal 2, result[:restored]  # 8 + 5 = 13, but capped at 10, so only +2
    assert_equal 10, result[:new_total]
    assert_equal 0, result[:credits_remaining]
    assert_equal 10, trainer.reload.adventures_remaining
  end

  test "claim_adventures should preserve banked credits" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 5,
      pokecenter_credits: 1,
      adventures_allocated_at: 1.day.ago
    )

    result = trainer.claim_adventures

    assert result[:success]
    assert_equal 5, result[:restored]
    assert_equal 10, result[:new_total]
    assert_equal 1, result[:credits_remaining]  # 1 banked + 1 day = 2, used 1 = 1 left
    assert_equal 10, trainer.reload.adventures_remaining
    assert_equal 1, trainer.pokecenter_credits
  end

  test "claim_adventures should update timestamp" do
    trainer = trainers(:ash)
    old_time = 2.days.ago
    trainer.update!(
      adventures_remaining: 2,
      pokecenter_credits: 0,
      adventures_allocated_at: old_time
    )

    result = trainer.claim_adventures

    assert result[:success]
    assert_in_delta Time.current.to_i, trainer.reload.adventures_allocated_at.to_i, 2
  end

  test "claim_adventures can be used twice on consecutive days" do
    trainer = trainers(:ash)

    # Day 1: First visit
    trainer.update!(
      adventures_remaining: 5,
      pokecenter_credits: 0,
      adventures_allocated_at: nil
    )
    result1 = trainer.claim_adventures

    assert result1[:success]
    assert_equal 10, trainer.reload.adventures_remaining
    assert_equal 0, trainer.pokecenter_credits

    # Use some adventures
    trainer.update!(adventures_remaining: 3)

    # Day 2: Visit again (1 day later)
    trainer.update!(adventures_allocated_at: 1.day.ago)
    result2 = trainer.claim_adventures

    assert result2[:success]
    assert_equal 5, result2[:restored]
    assert_equal 8, result2[:new_total]
    assert_equal 8, trainer.reload.adventures_remaining
  end

  test "claim_adventures can store up to 2 credits" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 0,
      pokecenter_credits: 0,
      adventures_allocated_at: 2.days.ago
    )

    # First visit - should have 2 credits available
    result1 = trainer.claim_adventures

    assert result1[:success]
    assert_equal 5, result1[:restored]
    assert_equal 5, result1[:new_total]
    assert_equal 1, result1[:credits_remaining]  # Used 1 of 2
    assert_equal 1, trainer.reload.pokecenter_credits

    # Second visit immediately - should still have 1 credit
    result2 = trainer.claim_adventures

    assert result2[:success]
    assert_equal 5, result2[:restored]
    assert_equal 10, result2[:new_total]
    assert_equal 0, result2[:credits_remaining]  # Used last credit
    assert_equal 0, trainer.reload.pokecenter_credits
  end

  test "claim_adventures from 7 adventures should cap at 10" do
    trainer = trainers(:ash)
    trainer.update!(
      adventures_remaining: 7,
      pokecenter_credits: 0,
      adventures_allocated_at: 1.day.ago
    )

    result = trainer.claim_adventures

    assert result[:success]
    assert_equal 3, result[:restored]  # 7 + 5 = 12, capped at 10, so only +3
    assert_equal 10, result[:new_total]
    assert_equal 10, trainer.reload.adventures_remaining
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

  test "time_until_next_adventure should return time until midnight if visited today" do
    trainer = trainers(:ash)
    # Set to today at noon to ensure it's definitely "today"
    today_noon = Date.current.to_time + 12.hours
    trainer.update!(adventures_allocated_at: today_noon)

    # Should have time remaining until midnight tomorrow
    time_remaining = trainer.time_until_next_adventure

    assert_operator time_remaining, :>, 0
    # Should be less than 24 hours (time until midnight)
    assert_operator time_remaining, :<, 24.hours.to_i
  end

  test "time_until_next_adventure should return 0 if last visit was yesterday" do
    trainer = trainers(:ash)
    trainer.update!(adventures_allocated_at: 1.day.ago) # Yesterday

    assert_equal 0, trainer.time_until_next_adventure
  end

  test "time_until_next_adventure should return 0 if last visit was 2+ days ago" do
    trainer = trainers(:ash)
    trainer.update!(adventures_allocated_at: 3.days.ago)

    assert_equal 0, trainer.time_until_next_adventure
  end

  test "formatted_time_until_adventure should return 'now' when claimable" do
    trainer = trainers(:ash)
    trainer.update!(adventures_allocated_at: 1.day.ago) # Yesterday - claimable

    assert_equal "now", trainer.formatted_time_until_adventure
  end

  test "formatted_time_until_adventure should format hours and minutes when visited today" do
    trainer = trainers(:ash)
    # Set to today at noon to ensure it's definitely "today"
    today_noon = Date.current.to_time + 12.hours
    trainer.update!(adventures_allocated_at: today_noon)

    formatted = trainer.formatted_time_until_adventure
    time_remaining = trainer.time_until_next_adventure

    # Should show time until midnight (hours and possibly minutes)
    assert_operator time_remaining, :>, 0
    assert_match /\d+/, formatted # Should contain numbers
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

  test "use_potion should not update adventures_allocated_at timestamp" do
    trainer = trainers(:ash)
    original_time = 2.days.ago
    trainer.update!(adventures_remaining: 5, adventures_allocated_at: original_time)
    trainer.add_item(:potion, 1)

    result = trainer.use_potion(:potion)

    assert result[:success]
    # Timestamp should not change when using potion
    assert_equal original_time.to_i, trainer.reload.adventures_allocated_at.to_i
    assert_equal 8, trainer.adventures_remaining
  end
end
