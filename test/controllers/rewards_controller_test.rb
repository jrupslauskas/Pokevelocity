require "test_helper"

class RewardsControllerTest < ActionDispatch::IntegrationTest
  # ================================================================================
  # BUY ITEMS - SUCCESSFUL PURCHASE TESTS
  # ================================================================================

  test "should successfully buy evolution stone when trainer has enough currency" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_stones = trainer.item_quantity(:fire_stone)

    post buy_item_rewards_path, params: { item_key: "fire_stone" }

    assert_redirected_to rewards_path
    assert_match "Successfully purchased Fire Stone for 300 Pokedollars!", flash[:notice]

    trainer.reload
    assert_equal initial_currency - 300, trainer.currency
    assert_equal initial_stones + 1, trainer.item_quantity(:fire_stone)
  end

  test "should successfully buy thunder stone" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_stones = trainer.item_quantity(:thunder_stone)

    post buy_item_rewards_path, params: { item_key: "thunder_stone" }

    assert_redirected_to rewards_path
    trainer.reload
    assert_equal initial_currency - 300, trainer.currency
    assert_equal initial_stones + 1, trainer.item_quantity(:thunder_stone)
  end

  test "should successfully buy water stone" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_stones = trainer.item_quantity(:water_stone)

    post buy_item_rewards_path, params: { item_key: "water_stone" }

    assert_redirected_to rewards_path
    trainer.reload
    assert_equal initial_currency - 300, trainer.currency
    assert_equal initial_stones + 1, trainer.item_quantity(:water_stone)
  end

  test "should successfully buy moon stone" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_stones = trainer.item_quantity(:moon_stone)

    post buy_item_rewards_path, params: { item_key: "moon_stone" }

    assert_redirected_to rewards_path
    trainer.reload
    assert_equal initial_currency - 300, trainer.currency
    assert_equal initial_stones + 1, trainer.item_quantity(:moon_stone)
  end

  test "should successfully buy leaf stone" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_stones = trainer.item_quantity(:leaf_stone)

    post buy_item_rewards_path, params: { item_key: "leaf_stone" }

    assert_redirected_to rewards_path
    trainer.reload
    assert_equal initial_currency - 300, trainer.currency
    assert_equal initial_stones + 1, trainer.item_quantity(:leaf_stone)
  end

  test "should successfully buy transfer cable" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_cables = trainer.item_quantity(:transfer_cable)

    post buy_item_rewards_path, params: { item_key: "transfer_cable" }

    assert_redirected_to rewards_path
    trainer.reload
    assert_equal initial_currency - 300, trainer.currency
    assert_equal initial_cables + 1, trainer.item_quantity(:transfer_cable)
  end

  test "should successfully buy evolution stone" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_stones = trainer.item_quantity(:evolution_stone)

    post buy_item_rewards_path, params: { item_key: "evolution_stone" }

    assert_redirected_to rewards_path
    trainer.reload
    assert_equal initial_currency - 100, trainer.currency
    assert_equal initial_stones + 1, trainer.item_quantity(:evolution_stone)
  end

  test "should successfully buy multiple items in sequence" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency

    # Buy fire stone (300)
    post buy_item_rewards_path, params: { item_key: "fire_stone" }
    trainer.reload
    assert_equal initial_currency - 300, trainer.currency

    # Buy water stone (300)
    post buy_item_rewards_path, params: { item_key: "water_stone" }
    trainer.reload
    assert_equal initial_currency - 600, trainer.currency

    # Buy thunder stone (300)
    post buy_item_rewards_path, params: { item_key: "thunder_stone" }
    trainer.reload
    assert_equal initial_currency - 900, trainer.currency
  end

  test "should successfully buy same item multiple times" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_stones = trainer.item_quantity(:fire_stone)

    # Buy fire stone 3 times
    3.times do
      post buy_item_rewards_path, params: { item_key: "fire_stone" }
    end

    trainer.reload
    assert_equal initial_stones + 3, trainer.item_quantity(:fire_stone)
  end

  # ================================================================================
  # BUY ITEMS - ERROR HANDLING TESTS
  # ================================================================================

  test "should not buy item when trainer has insufficient currency" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Set currency to less than item price (fire_stone costs 300)
    trainer.update!(currency: 50)
    initial_currency = trainer.currency
    initial_stones = trainer.item_quantity(:fire_stone)

    post buy_item_rewards_path, params: { item_key: "fire_stone" }

    assert_redirected_to rewards_path
    assert_match "Not enough money! You need 300 but only have 50", flash[:alert]

    trainer.reload
    assert_equal initial_currency, trainer.currency
    assert_equal initial_stones, trainer.item_quantity(:fire_stone)
  end

  test "should not buy item when trainer has exactly zero currency" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    trainer.update!(currency: 0)
    initial_stones = trainer.item_quantity(:fire_stone)

    post buy_item_rewards_path, params: { item_key: "fire_stone" }

    assert_redirected_to rewards_path
    assert_match "Not enough money!", flash[:alert]

    trainer.reload
    assert_equal 0, trainer.currency
    assert_equal initial_stones, trainer.item_quantity(:fire_stone)
  end

  test "should successfully buy pokeball for 200" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_pokeballs = trainer.item_quantity(:pokeball)

    post buy_item_rewards_path, params: { item_key: "pokeball" }

    assert_redirected_to rewards_path
    assert_match "Successfully purchased Poké Ball for 200 Pokedollars!", flash[:notice]

    trainer.reload
    assert_equal initial_currency - 200, trainer.currency
    assert_equal initial_pokeballs + 1, trainer.item_quantity(:pokeball)
  end

  test "should successfully buy great ball for 300" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_great_balls = trainer.item_quantity(:great_ball)

    post buy_item_rewards_path, params: { item_key: "great_ball" }

    assert_redirected_to rewards_path
    assert_match "Successfully purchased Great Ball for 300 Pokedollars!", flash[:notice]

    trainer.reload
    assert_equal initial_currency - 300, trainer.currency
    assert_equal initial_great_balls + 1, trainer.item_quantity(:great_ball)
  end

  test "should successfully buy ultra ball for 400" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_ultra_balls = trainer.item_quantity(:ultra_ball)

    post buy_item_rewards_path, params: { item_key: "ultra_ball" }

    assert_redirected_to rewards_path
    assert_match "Successfully purchased Ultra Ball for 400 Pokedollars!", flash[:notice]

    trainer.reload
    assert_equal initial_currency - 400, trainer.currency
    assert_equal initial_ultra_balls + 1, trainer.item_quantity(:ultra_ball)
  end

  test "should successfully buy master ball for 700" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_master_balls = trainer.item_quantity(:master_ball)

    post buy_item_rewards_path, params: { item_key: "master_ball" }

    assert_redirected_to rewards_path
    assert_match "Successfully purchased Master Ball for 700 Pokedollars!", flash[:notice]

    trainer.reload
    assert_equal initial_currency - 700, trainer.currency
    assert_equal initial_master_balls + 1, trainer.item_quantity(:master_ball)
  end

  test "should not buy pokeball when trainer has insufficient currency" do
    trainer = trainers(:ash)
    trainer.update!(currency: 50)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_pokeballs = trainer.item_quantity(:pokeball)

    post buy_item_rewards_path, params: { item_key: "pokeball" }

    assert_redirected_to rewards_path
    assert_match "Not enough money! You need 200 but only have 50", flash[:alert]

    trainer.reload
    assert_equal initial_currency, trainer.currency
    assert_equal initial_pokeballs, trainer.item_quantity(:pokeball)
  end

  test "should successfully buy multiple different pokeballs in sequence" do
    trainer = trainers(:ash)
    trainer.update!(currency: 2000)
    log_in_as(trainer)

    initial_currency = trainer.currency

    # Buy pokeball (200)
    post buy_item_rewards_path, params: { item_key: "pokeball" }
    trainer.reload
    assert_equal initial_currency - 200, trainer.currency

    # Buy great ball (300)
    post buy_item_rewards_path, params: { item_key: "great_ball" }
    trainer.reload
    assert_equal initial_currency - 500, trainer.currency

    # Buy ultra ball (400)
    post buy_item_rewards_path, params: { item_key: "ultra_ball" }
    trainer.reload
    assert_equal initial_currency - 900, trainer.currency

    # Buy master ball (500)
    post buy_item_rewards_path, params: { item_key: "master_ball" }
    trainer.reload
    assert_equal initial_currency - 1600, trainer.currency
  end

  test "should not buy non-existent item" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_currency = trainer.currency

    post buy_item_rewards_path, params: { item_key: "nonexistent_item" }

    assert_redirected_to rewards_path
    assert_match "Item not found", flash[:alert]

    trainer.reload
    assert_equal initial_currency, trainer.currency
  end

  test "should redirect to login when buying without authentication" do
    post buy_item_rewards_path, params: { item_key: "fire_stone" }
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "should handle buying with exact currency amount" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Set currency to exactly item price (fire_stone costs 300)
    trainer.update!(currency: 300)
    initial_stones = trainer.item_quantity(:fire_stone)

    post buy_item_rewards_path, params: { item_key: "fire_stone" }

    assert_redirected_to rewards_path
    assert_match "Successfully purchased", flash[:notice]

    trainer.reload
    assert_equal 0, trainer.currency
    assert_equal initial_stones + 1, trainer.item_quantity(:fire_stone)
  end

  # ================================================================================
  # SELL ITEMS - SUCCESSFUL SALE TESTS
  # ================================================================================

  test "should successfully sell evolution stone when trainer has one" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer a fire stone
    trainer.add_item(:fire_stone, 1)
    initial_currency = trainer.currency
    initial_stones = trainer.item_quantity(:fire_stone)

    post sell_item_rewards_path, params: { item_key: "fire_stone" }

    assert_redirected_to rewards_path
    assert_match "Successfully sold Fire Stone for 200 Pokedollars!", flash[:notice]

    trainer.reload
    assert_equal initial_currency + 200, trainer.currency
    assert_equal initial_stones - 1, trainer.item_quantity(:fire_stone)
  end

  test "should successfully sell thunder stone" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    trainer.add_item(:thunder_stone, 1)
    initial_currency = trainer.currency
    initial_stones = trainer.item_quantity(:thunder_stone)

    post sell_item_rewards_path, params: { item_key: "thunder_stone" }

    assert_redirected_to rewards_path
    trainer.reload
    assert_equal initial_currency + 200, trainer.currency
    assert_equal initial_stones - 1, trainer.item_quantity(:thunder_stone)
  end

  test "should successfully sell water stone" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    trainer.add_item(:water_stone, 1)
    initial_currency = trainer.currency
    initial_stones = trainer.item_quantity(:water_stone)

    post sell_item_rewards_path, params: { item_key: "water_stone" }

    assert_redirected_to rewards_path
    trainer.reload
    assert_equal initial_currency + 200, trainer.currency
    assert_equal initial_stones - 1, trainer.item_quantity(:water_stone)
  end

  test "should successfully sell pokeball" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_pokeballs = trainer.item_quantity(:pokeball)

    post sell_item_rewards_path, params: { item_key: "pokeball" }

    assert_redirected_to rewards_path
    assert_match "Successfully sold Poké Ball for 100 Pokedollars!", flash[:notice]

    trainer.reload
    assert_equal initial_currency + 100, trainer.currency
    assert_equal initial_pokeballs - 1, trainer.item_quantity(:pokeball)
  end

  test "should successfully sell great ball" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_great_balls = trainer.item_quantity(:great_ball)

    post sell_item_rewards_path, params: { item_key: "great_ball" }

    assert_redirected_to rewards_path
    trainer.reload
    assert_equal initial_currency + 200, trainer.currency
    assert_equal initial_great_balls - 1, trainer.item_quantity(:great_ball)
  end

  test "should successfully sell ultra ball" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_ultra_balls = trainer.item_quantity(:ultra_ball)

    post sell_item_rewards_path, params: { item_key: "ultra_ball" }

    assert_redirected_to rewards_path
    trainer.reload
    assert_equal initial_currency + 300, trainer.currency
    assert_equal initial_ultra_balls - 1, trainer.item_quantity(:ultra_ball)
  end

  test "should successfully sell master ball" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_master_balls = trainer.item_quantity(:master_ball)

    post sell_item_rewards_path, params: { item_key: "master_ball" }

    assert_redirected_to rewards_path
    trainer.reload
    assert_equal initial_currency + 500, trainer.currency
    assert_equal initial_master_balls - 1, trainer.item_quantity(:master_ball)
  end

  test "should successfully sell multiple items in sequence" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer items
    trainer.add_item(:fire_stone, 1)
    trainer.add_item(:water_stone, 1)
    trainer.add_item(:thunder_stone, 1)

    initial_currency = trainer.currency

    # Sell all three (each worth 200)
    post sell_item_rewards_path, params: { item_key: "fire_stone" }
    trainer.reload
    assert_equal initial_currency + 200, trainer.currency

    post sell_item_rewards_path, params: { item_key: "water_stone" }
    trainer.reload
    assert_equal initial_currency + 400, trainer.currency

    post sell_item_rewards_path, params: { item_key: "thunder_stone" }
    trainer.reload
    assert_equal initial_currency + 600, trainer.currency
  end

  test "should successfully sell multiple of same item" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    trainer.add_item(:fire_stone, 5)
    initial_currency = trainer.currency
    initial_stones = trainer.item_quantity(:fire_stone)

    # Sell 3 fire stones (each worth 200)
    3.times do
      post sell_item_rewards_path, params: { item_key: "fire_stone" }
    end

    trainer.reload
    assert_equal initial_currency + 600, trainer.currency
    assert_equal initial_stones - 3, trainer.item_quantity(:fire_stone)
  end

  # ================================================================================
  # SELL ITEMS - ERROR HANDLING TESTS
  # ================================================================================

  test "should not sell item when trainer has none" do
    trainer = trainers(:broke_trainer)
    log_in_as(trainer)

    # Broke trainer has no items
    initial_currency = trainer.currency

    post sell_item_rewards_path, params: { item_key: "fire_stone" }

    assert_redirected_to rewards_path
    assert_match "You don't have any Fire Stone to sell", flash[:alert]

    trainer.reload
    assert_equal initial_currency, trainer.currency
  end

  test "should not sell pokeball when trainer has zero" do
    trainer = trainers(:broke_trainer)
    log_in_as(trainer)

    initial_currency = trainer.currency

    post sell_item_rewards_path, params: { item_key: "pokeball" }

    assert_redirected_to rewards_path
    assert_match "You don't have any Poké Ball to sell", flash[:alert]

    trainer.reload
    assert_equal initial_currency, trainer.currency
  end

  test "should not sell non-existent item" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_currency = trainer.currency

    post sell_item_rewards_path, params: { item_key: "nonexistent_item" }

    assert_redirected_to rewards_path
    assert_match "Item not found", flash[:alert]

    trainer.reload
    assert_equal initial_currency, trainer.currency
  end

  test "should redirect to login when selling without authentication" do
    post sell_item_rewards_path, params: { item_key: "pokeball" }
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "should not sell last pokeball when trainer has exactly one" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Sell all but 1 pokeball
    initial_pokeballs = trainer.item_quantity(:pokeball)
    (initial_pokeballs - 1).times do
      post sell_item_rewards_path, params: { item_key: "pokeball" }
    end

    trainer.reload
    assert_equal 1, trainer.item_quantity(:pokeball)

    # Should still be able to sell the last one
    initial_currency = trainer.currency
    post sell_item_rewards_path, params: { item_key: "pokeball" }

    trainer.reload
    assert_equal 0, trainer.item_quantity(:pokeball)
    assert_equal initial_currency + 100, trainer.currency
  end

  # ================================================================================
  # BUY/SELL COMBINED WORKFLOW TESTS
  # ================================================================================

  test "should be able to buy and sell same item" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency

    # Buy fire stone (costs 300)
    post buy_item_rewards_path, params: { item_key: "fire_stone" }
    trainer.reload
    assert_equal initial_currency - 300, trainer.currency
    assert_equal 1, trainer.item_quantity(:fire_stone)

    # Sell it back (sells for 200)
    post sell_item_rewards_path, params: { item_key: "fire_stone" }
    trainer.reload
    assert_equal initial_currency - 100, trainer.currency
    assert_equal 0, trainer.item_quantity(:fire_stone)
  end

  test "should accumulate currency from multiple sells" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_pokeballs = trainer.item_quantity(:pokeball)

    # Sell all pokeballs
    initial_pokeballs.times do
      post sell_item_rewards_path, params: { item_key: "pokeball" }
    end

    trainer.reload
    assert_equal initial_currency + (initial_pokeballs * 100), trainer.currency
    assert_equal 0, trainer.item_quantity(:pokeball)
  end

  test "should maintain session across buy/sell operations" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Buy an item
    post buy_item_rewards_path, params: { item_key: "fire_stone" }
    assert_equal trainer.id, session[:trainer_id]

    # Sell an item
    post sell_item_rewards_path, params: { item_key: "pokeball" }
    assert_equal trainer.id, session[:trainer_id]
  end

  test "should handle buying with minimum currency requirement" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Set currency to 99 (1 less than needed)
    trainer.update!(currency: 99)

    post buy_item_rewards_path, params: { item_key: "fire_stone" }

    assert_redirected_to rewards_path
    assert_match "Not enough money!", flash[:alert]

    trainer.reload
    assert_equal 99, trainer.currency
  end

  test "should increase currency beyond initial amount through sales" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    initial_currency = trainer.currency

    # Sell all items
    total_items = trainer.item_quantity(:pokeball) +
                  trainer.item_quantity(:great_ball) +
                  trainer.item_quantity(:ultra_ball) +
                  trainer.item_quantity(:master_ball)

    # Sell pokeballs
    trainer.item_quantity(:pokeball).times do
      post sell_item_rewards_path, params: { item_key: "pokeball" }
    end

    trainer.reload
    assert trainer.currency > initial_currency
  end

  # ================================================================================
  # EDGE CASE TESTS
  # ================================================================================

  test "should handle rapid successive purchases" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Ensure enough currency
    trainer.update!(currency: 10000)

    # Buy 10 fire stones rapidly (each costs 300)
    10.times do
      post buy_item_rewards_path, params: { item_key: "fire_stone" }
    end

    trainer.reload
    assert_equal 10, trainer.item_quantity(:fire_stone)
    assert_equal 7000, trainer.currency
  end

  test "should handle rapid successive sales" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Give trainer many items
    trainer.add_item(:fire_stone, 10)
    initial_currency = trainer.currency

    # Sell 10 fire stones rapidly (each sells for 200)
    10.times do
      post sell_item_rewards_path, params: { item_key: "fire_stone" }
    end

    trainer.reload
    assert_equal 0, trainer.item_quantity(:fire_stone)
    assert_equal initial_currency + 2000, trainer.currency
  end

  test "should display different flash messages for buy and sell" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    # Buy
    post buy_item_rewards_path, params: { item_key: "fire_stone" }
    assert_match "Successfully purchased", flash[:notice]

    # Sell
    post sell_item_rewards_path, params: { item_key: "pokeball" }
    assert_match "Successfully sold", flash[:notice]
  end

  test "should handle trainer with maximum currency" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Set very high currency
    trainer.update!(currency: 1000000)

    post buy_item_rewards_path, params: { item_key: "fire_stone" }

    trainer.reload
    assert_equal 999700, trainer.currency
  end

  # ================================================================================
  # POTION TESTS
  # ================================================================================

  test "should successfully buy potion for 100" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_potions = trainer.item_quantity(:potion)

    post buy_item_rewards_path, params: { item_key: "potion" }

    assert_redirected_to rewards_path
    assert_match "Successfully purchased Potion for 100 Pokedollars!", flash[:notice]

    trainer.reload
    assert_equal initial_currency - 100, trainer.currency
    assert_equal initial_potions + 1, trainer.item_quantity(:potion)
  end

  test "should successfully buy super_potion for 200" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_potions = trainer.item_quantity(:super_potion)

    post buy_item_rewards_path, params: { item_key: "super_potion" }

    assert_redirected_to rewards_path
    assert_match "Successfully purchased Super Potion for 200 Pokedollars!", flash[:notice]

    trainer.reload
    assert_equal initial_currency - 200, trainer.currency
    assert_equal initial_potions + 1, trainer.item_quantity(:super_potion)
  end

  test "should successfully buy hyper_potion for 300" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_potions = trainer.item_quantity(:hyper_potion)

    post buy_item_rewards_path, params: { item_key: "hyper_potion" }

    assert_redirected_to rewards_path
    assert_match "Successfully purchased Hyper Potion for 300 Pokedollars!", flash[:notice]

    trainer.reload
    assert_equal initial_currency - 300, trainer.currency
    assert_equal initial_potions + 1, trainer.item_quantity(:hyper_potion)
  end

  test "should successfully sell potion for 100" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    trainer.add_item(:potion, 1)
    initial_currency = trainer.currency
    initial_potions = trainer.item_quantity(:potion)

    post sell_item_rewards_path, params: { item_key: "potion" }

    assert_redirected_to rewards_path
    assert_match "Successfully sold Potion for 100 Pokedollars!", flash[:notice]

    trainer.reload
    assert_equal initial_currency + 100, trainer.currency
    assert_equal initial_potions - 1, trainer.item_quantity(:potion)
  end

  test "should successfully sell super_potion for 200" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    trainer.add_item(:super_potion, 1)
    initial_currency = trainer.currency
    initial_potions = trainer.item_quantity(:super_potion)

    post sell_item_rewards_path, params: { item_key: "super_potion" }

    assert_redirected_to rewards_path
    assert_match "Successfully sold Super Potion for 200 Pokedollars!", flash[:notice]

    trainer.reload
    assert_equal initial_currency + 200, trainer.currency
    assert_equal initial_potions - 1, trainer.item_quantity(:super_potion)
  end

  test "should successfully sell hyper_potion for 300" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    trainer.add_item(:hyper_potion, 1)
    initial_currency = trainer.currency
    initial_potions = trainer.item_quantity(:hyper_potion)

    post sell_item_rewards_path, params: { item_key: "hyper_potion" }

    assert_redirected_to rewards_path
    assert_match "Successfully sold Hyper Potion for 300 Pokedollars!", flash[:notice]

    trainer.reload
    assert_equal initial_currency + 300, trainer.currency
    assert_equal initial_potions - 1, trainer.item_quantity(:hyper_potion)
  end

  test "should not buy potion when trainer has insufficient currency" do
    trainer = trainers(:ash)
    trainer.update!(currency: 50)
    log_in_as(trainer)

    initial_currency = trainer.currency
    initial_potions = trainer.item_quantity(:potion)

    post buy_item_rewards_path, params: { item_key: "potion" }

    assert_redirected_to rewards_path
    assert_match "Not enough money! You need 100 but only have 50", flash[:alert]

    trainer.reload
    assert_equal initial_currency, trainer.currency
    assert_equal initial_potions, trainer.item_quantity(:potion)
  end

  test "should successfully buy multiple different potions in sequence" do
    trainer = trainers(:ash)
    trainer.update!(currency: 1000)
    log_in_as(trainer)

    initial_currency = trainer.currency

    # Buy potion (100)
    post buy_item_rewards_path, params: { item_key: "potion" }
    trainer.reload
    assert_equal initial_currency - 100, trainer.currency

    # Buy super_potion (200)
    post buy_item_rewards_path, params: { item_key: "super_potion" }
    trainer.reload
    assert_equal initial_currency - 300, trainer.currency

    # Buy hyper_potion (300)
    post buy_item_rewards_path, params: { item_key: "hyper_potion" }
    trainer.reload
    assert_equal initial_currency - 600, trainer.currency
  end

  private

  # Helper method to log in a trainer
  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end
end
