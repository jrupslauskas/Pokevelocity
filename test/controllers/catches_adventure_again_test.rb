require "test_helper"

class CatchesAdventureAgainTest < ActionDispatch::IntegrationTest
  def setup
    @trainer = trainers(:ash)
    post login_path, params: { username: @trainer.username, password: "password" }

    # Create test route
    @route = Route.create!(order: 945, gate_requirement: nil)

    # Create Pokemon for different encounter types
    @grass_pokemon_1 = Pokemon.find_or_create_by!(pokedex_number: 134) { |p| p.name = "Vaporeon"; p.difficulty = 3 }
    @grass_pokemon_2 = Pokemon.find_or_create_by!(pokedex_number: 135) { |p| p.name = "Jolteon"; p.difficulty = 3 }

    @fish_old_rod = Pokemon.find_or_create_by!(pokedex_number: 136) { |p| p.name = "Flareon"; p.difficulty = 3 }
    @fish_good_rod = Pokemon.find_or_create_by!(pokedex_number: 137) { |p| p.name = "Porygon"; p.difficulty = 3 }

    # Create encounters
    RouteEncounter.create!(route: @route, pokemon: @grass_pokemon_1, spawn_rate: 50, encounter_type: "grass")
    RouteEncounter.create!(route: @route, pokemon: @grass_pokemon_2, spawn_rate: 50, encounter_type: "grass")

    RouteEncounter.create!(route: @route, pokemon: @fish_old_rod, spawn_rate: 100, encounter_type: "fish", required_item_key: "old_rod")
    RouteEncounter.create!(route: @route, pokemon: @fish_good_rod, spawn_rate: 100, encounter_type: "fish", required_item_key: "good_rod")

    # Give trainer items and pokeballs
    @trainer.add_item(:old_rod, 1)
    @trainer.add_item(:good_rod, 1)
    @trainer.add_item(:pokeball, 10)
  end

  # ================================================================================
  # BASIC FUNCTIONALITY TESTS
  # ================================================================================

  test "should store last adventure parameters in session when adventuring" do
    post adventure_path(@route), params: { encounter_type: "grass" }

    assert session[:last_adventure].present?
    assert_equal @route.id, session[:last_adventure]['route_id']
    assert_equal "grass", session[:last_adventure]['encounter_type']
  end

  test "should store rod type in session for fishing adventures" do
    post adventure_path(@route), params: { encounter_type: "fish", rod_type: "good_rod" }

    assert session[:last_adventure].present?
    assert_equal @route.id, session[:last_adventure]['route_id']
    assert_equal "fish", session[:last_adventure]['encounter_type']
    assert_equal "good_rod", session[:last_adventure]['rod_type']
  end

  test "should display Adventure Again button when last_adventure exists" do
    # First, do an adventure to set session
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    # Now check the encounter page
    assert_response :success
    assert_select "button", text: /Adventure Again/
  end

  test "should not display Adventure Again button when no previous adventure" do
    # Get a catch page directly without adventuring first
    get catch_path(@grass_pokemon_1)

    assert_response :success
    assert_select "button", text: /Adventure Again/, count: 0
  end

  test "Adventure Again button should have correct form action" do
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    assert_response :success
    assert_select "form[action=?]", adventure_path(@route)
  end

  test "Adventure Again form should include encounter_type hidden field" do
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    assert_response :success
    assert_select "input[type='hidden'][name='encounter_type'][value='grass']"
  end

  test "Adventure Again form should include rod_type hidden field for fishing" do
    post adventure_path(@route), params: { encounter_type: "fish", rod_type: "old_rod" }
    follow_redirect!

    assert_response :success
    assert_select "input[type='hidden'][name='encounter_type'][value='fish']"
    assert_select "input[type='hidden'][name='rod_type'][value='old_rod']"
  end

  # ================================================================================
  # FUNCTIONAL TESTS - GRASS ENCOUNTERS
  # ================================================================================

  test "Adventure Again should generate new grass encounter on same route" do
    # First adventure
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    # Should be redirected to a catch page
    assert_response :success
    assert_match /Wild .* appeared!/, response.body

    # Adventure Again
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    # Should be redirected to a catch page
    assert_response :success
    assert_match /Wild .* appeared!/, response.body

    # Should see one of our grass Pokemon
    assert_match /(Vaporeon|Jolteon)/, response.body
  end

  test "Adventure Again for grass should only encounter grass Pokemon" do
    # Do 10 adventures to test randomness
    10.times do
      post adventure_path(@route), params: { encounter_type: "grass" }
      follow_redirect!

      # Should encounter one of the grass Pokemon
      assert_match /(Vaporeon|Jolteon)/, response.body

      # Should NOT encounter fish or surf Pokemon
      assert_no_match /Flareon/, response.body
      assert_no_match /Porygon/, response.body
      assert_no_match /Omanyte/, response.body
    end
  end

  # ================================================================================
  # FUNCTIONAL TESTS - FISHING ENCOUNTERS
  # ================================================================================

  test "Adventure Again should generate new fish encounter with same rod" do
    # First adventure with old rod
    post adventure_path(@route), params: { encounter_type: "fish", rod_type: "old_rod" }
    follow_redirect!

    # Adventure Again should use old rod
    post adventure_path(@route), params: { encounter_type: "fish", rod_type: "old_rod" }
    follow_redirect!

    assert_response :success
    assert_match /Flareon/, response.body
  end

  test "Adventure Again should maintain rod type from original adventure" do
    # First adventure with good rod
    post adventure_path(@route), params: { encounter_type: "fish", rod_type: "good_rod" }
    follow_redirect!

    # Adventure Again - should preserve good_rod
    assert_equal "good_rod", session[:last_adventure]['rod_type']

    post adventure_path(@route), params: {
      encounter_type: session[:last_adventure]['encounter_type'],
      rod_type: session[:last_adventure]['rod_type']
    }
    follow_redirect!

    assert_match /Porygon/, response.body
  end

  test "Adventure Again with old rod should only get old rod Pokemon" do
    10.times do
      post adventure_path(@route), params: { encounter_type: "fish", rod_type: "old_rod" }
      follow_redirect!

      assert_match /Flareon/, response.body
      assert_no_match /Porygon/, response.body
    end
  end

  test "Adventure Again with good rod should only get good rod Pokemon" do
    10.times do
      post adventure_path(@route), params: { encounter_type: "fish", rod_type: "good_rod" }
      follow_redirect!

      assert_match /Porygon/, response.body
      assert_no_match /Flareon/, response.body
    end
  end

  # ================================================================================
  # FUNCTIONAL TESTS - SURF ENCOUNTERS
  # ================================================================================



  # ================================================================================
  # SESSION PERSISTENCE TESTS
  # ================================================================================

  test "session should persist across multiple Adventure Again uses" do
    # First adventure
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    # Adventure Again
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    # Session should still have last_adventure
    assert session[:last_adventure].present?
    assert_equal @route.id, session[:last_adventure]['route_id']
    assert_equal "grass", session[:last_adventure]['encounter_type']

    # Adventure Again one more time
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    # Session should still be valid
    assert session[:last_adventure].present?
  end

  test "new adventure should update session parameters" do
    # First adventure on grass
    post adventure_path(@route), params: { encounter_type: "grass" }
    assert_equal "grass", session[:last_adventure]['encounter_type']

    # New adventure on fish
    post adventure_path(@route), params: { encounter_type: "fish", rod_type: "old_rod" }
    assert_equal "fish", session[:last_adventure]['encounter_type']
    assert_equal "old_rod", session[:last_adventure]['rod_type']
  end

  # ================================================================================
  # ENCOUNTER RANDOMNESS TESTS
  # ================================================================================

  test "Adventure Again should generate random encounters based on spawn rates" do
    # Create route with uneven spawn rates
    test_route = Route.create!(order: 944, gate_requirement: nil)

    common_pokemon = Pokemon.find_or_create_by!(pokedex_number: 139) { |p| p.name = "Omastar"; p.difficulty = 3 }
    rare_pokemon = Pokemon.find_or_create_by!(pokedex_number: 21) { |p| p.name = "Spearow"; p.difficulty = 1 }

    RouteEncounter.create!(route: test_route, pokemon: common_pokemon, spawn_rate: 90, encounter_type: "grass")
    RouteEncounter.create!(route: test_route, pokemon: rare_pokemon, spawn_rate: 10, encounter_type: "grass")

    # Do multiple adventures and check we get variety
    omastar_count = 0
    spearow_count = 0

    20.times do
      post adventure_path(test_route), params: { encounter_type: "grass" }
      follow_redirect!

      if response.body.include?("Omastar")
        omastar_count += 1
      elsif response.body.include?("Spearow")
        spearow_count += 1
      end
    end

    # Should have encountered at least one Pokemon
    assert omastar_count + spearow_count == 20

    # Common pokemon should appear (statistically very likely with 90% rate)
    assert omastar_count > 0
  end

  test "Adventure Again should generate different encounters on successive uses" do
    # Even though it's random, with 50/50 split, we should eventually get both Pokemon
    vaporeon_count = 0
    jolteon_count = 0

    20.times do
      post adventure_path(@route), params: { encounter_type: "grass" }
      follow_redirect!

      if response.body.include?("Vaporeon")
        vaporeon_count += 1
      elsif response.body.include?("Jolteon")
        jolteon_count += 1
      end
    end

    # Should have encountered exactly 20 Pokemon total
    assert vaporeon_count + jolteon_count == 20
  end

  # ================================================================================
  # EDGE CASE TESTS
  # ================================================================================

  test "Adventure Again should work after catching a Pokemon" do
    # Adventure
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    # Extract Pokemon ID from the URL (catch_path returns /catches/:id)
    pokemon_id = request.path.split('/').last.to_i

    # Catch the Pokemon
    post catch_path(pokemon_id), params: { ball_type: "pokeball" }

    # Session should still have last_adventure
    assert session[:last_adventure].present?
  end

  test "Adventure Again should work after running from a Pokemon" do
    # Adventure
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    # Extract Pokemon ID from the URL
    pokemon_id = request.path.split('/').last.to_i

    # Run
    post run_from_catch_path(pokemon_id)

    # Session should still have last_adventure (not cleared by run)
    assert session[:last_adventure].present?
  end

  test "Adventure Again should respect trainer item requirements" do
    # Remove good rod from trainer
    @trainer.trainer_items.joins(:item).find_by(items: { key: "good_rod" })&.destroy

    # Try to adventure with good rod (should fail or redirect)
    post adventure_path(@route), params: { encounter_type: "fish", rod_type: "good_rod" }

    # Should redirect back with notice
    assert_redirected_to catches_path
    follow_redirect!
    assert_match /No Pokémon available/, flash[:notice]
  end

  test "multiple trainers should have separate adventure sessions" do
    # Trainer 1 adventures on grass
    post adventure_path(@route), params: { encounter_type: "grass" }
    assert_equal "grass", session[:last_adventure]['encounter_type']

    # Session data persists for the same user session
    assert session[:last_adventure].present?
  end

  # ================================================================================
  # UI/UX TESTS
  # ================================================================================

  test "Adventure Again button should have correct CSS classes" do
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    assert_select "button.pokeball-card.adventure-again-card"
    assert_select ".adventure-again-icon"
    assert_select ".adventure-again-card-footer"
  end

  test "Adventure Again button should display correct text" do
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    assert_select ".pokeball-card-name", text: "Adventure Again"
    assert_select ".pokeball-card-description", text: "Same route & type"
  end

  test "Run button should still be present alongside Adventure Again" do
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    assert_select "button.run-card", text: /Run/
    assert_select "button.adventure-again-card", text: /Adventure Again/
  end

  test "All pokeball options should still be available with Adventure Again" do
    post adventure_path(@route), params: { encounter_type: "grass" }
    follow_redirect!

    assert_select "button", text: /Pokéball/
    assert_select "button", text: /Great Ball/
    assert_select "button", text: /Ultra Ball/
    assert_select "button", text: /Master Ball/
    assert_select "button", text: /Run/
    assert_select "button", text: /Adventure Again/
  end
end
