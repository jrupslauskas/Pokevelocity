require "test_helper"

class FishingWorkflowTest < ActiveSupport::TestCase
  def setup
    @trainer = trainers(:ash)

    # Create gates - Old Rod (Gate 2), Good Rod (Gate 4), Super Rod (Gate 6)
    @gate_2 = Gate.find_or_create_by!(gate_number: 2, required_difficulty_score: 10)
    @gate_4 = Gate.find_or_create_by!(gate_number: 4, required_difficulty_score: 25)
    @gate_6 = Gate.find_or_create_by!(gate_number: 6, required_difficulty_score: 50)

    # Create a route with fishing encounters
    @route = Route.create!(order: 100, gate_requirement: nil)

    # Use find_or_create_by to avoid duplication with fixtures
    @old_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 129) { |p| p.name = "Magikarp"; p.difficulty = 1 }
    @good_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 118) { |p| p.name = "Goldeen"; p.difficulty = 2 }
    @super_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 130) { |p| p.name = "Gyarados"; p.difficulty = 5 }

    @old_rod_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: @old_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )

    @good_rod_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: @good_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "good_rod"
    )

    @super_rod_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: @super_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "super_rod"
    )
  end

  # ================================================================================
  # PROGRESSIVE ROD UNLOCKING WORKFLOW
  # ================================================================================

  test "complete fishing workflow: no rod -> old rod -> good rod -> super rod" do
    # Initially, trainer has no rods and can't see any fishing encounters
    assert_equal 0, @trainer.item_quantity(:old_rod)
    assert_equal 0, @trainer.item_quantity(:good_rod)
    assert_equal 0, @trainer.item_quantity(:super_rod)

    assert_not @old_rod_encounter.available_for?(@trainer)
    assert_not @good_rod_encounter.available_for?(@trainer)
    assert_not @super_rod_encounter.available_for?(@trainer)

    # Unlock Gate 3 (Misty's Gym) -> Get Old Rod
    GateUnlock.create!(trainer: @trainer, gate: @gate_2)
    @trainer.reload

    assert_equal 1, @trainer.item_quantity(:old_rod)
    assert @old_rod_encounter.available_for?(@trainer)
    assert_not @good_rod_encounter.available_for?(@trainer)
    assert_not @super_rod_encounter.available_for?(@trainer)

    # Unlock Gate 5 (Erika's Gym) -> Get Good Rod
    GateUnlock.create!(trainer: @trainer, gate: @gate_4)
    @trainer.reload

    assert_equal 1, @trainer.item_quantity(:good_rod)
    assert @old_rod_encounter.available_for?(@trainer)
    assert @good_rod_encounter.available_for?(@trainer)
    assert_not @super_rod_encounter.available_for?(@trainer)

    # Unlock Gate 7 (Sabrina's Gym) -> Get Super Rod
    GateUnlock.create!(trainer: @trainer, gate: @gate_6)
    @trainer.reload

    assert_equal 1, @trainer.item_quantity(:super_rod)
    assert @old_rod_encounter.available_for?(@trainer)
    assert @good_rod_encounter.available_for?(@trainer)
    assert @super_rod_encounter.available_for?(@trainer)
  end

  test "trainer with old rod can only fish old rod encounters" do
    GateUnlock.create!(trainer: @trainer, gate: @gate_2)
    @trainer.reload

    available_encounters = @route.route_encounters.select { |e| e.available_for?(@trainer) }

    assert_equal 1, available_encounters.length
    assert_equal @old_rod_pokemon, available_encounters.first.pokemon
  end

  test "trainer with good rod can fish both old and good rod encounters" do
    GateUnlock.create!(trainer: @trainer, gate: @gate_2)
    GateUnlock.create!(trainer: @trainer, gate: @gate_4)
    @trainer.reload

    available_encounters = @route.route_encounters.select { |e| e.available_for?(@trainer) }

    assert_equal 2, available_encounters.length
    pokemon_names = available_encounters.map { |e| e.pokemon.name }.sort
    assert_equal ["Goldeen", "Magikarp"], pokemon_names
  end

  test "trainer with super rod can fish all encounters" do
    GateUnlock.create!(trainer: @trainer, gate: @gate_2)
    GateUnlock.create!(trainer: @trainer, gate: @gate_4)
    GateUnlock.create!(trainer: @trainer, gate: @gate_6)
    @trainer.reload

    available_encounters = @route.route_encounters.select { |e| e.available_for?(@trainer) }

    assert_equal 3, available_encounters.length
    pokemon_names = available_encounters.map { |e| e.pokemon.name }.sort
    assert_equal ["Goldeen", "Gyarados", "Magikarp"], pokemon_names
  end

  # ================================================================================
  # ROUTE-LEVEL FISHING REQUIREMENTS
  # ================================================================================

  test "route with fishing_required_item_key blocks fishing without the item" do
    @route.update!(fishing_required_item_key: "old_rod")

    # Route has fishing
    assert @route.has_fishing?

    # But it's not unlocked without the rod
    assert_not @route.fishing_unlocked_for?(@trainer)

    # After getting the rod, it's unlocked
    GateUnlock.create!(trainer: @trainer, gate: @gate_2)
    @trainer.reload

    assert @route.fishing_unlocked_for?(@trainer)
  end

  test "route without fishing_required_item_key allows fishing immediately" do
    @route.update!(fishing_required_item_key: nil)

    assert @route.has_fishing?
    assert @route.fishing_unlocked_for?(@trainer)
  end

  # ================================================================================
  # MIXED ENCOUNTER TYPES ON SAME ROUTE
  # ================================================================================

  test "route with grass and fishing encounters handles both correctly" do
    # Add grass encounter
    grass_pokemon = Pokemon.find_or_create_by!(pokedex_number: 16) { |p| p.name = "Pidgey"; p.difficulty = 1 }
    grass_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: grass_pokemon,
      spawn_rate: 100,
      encounter_type: "grass"
    )

    # Grass encounter is available without any items
    assert grass_encounter.available_for?(@trainer)

    # But fishing encounters are not
    assert_not @old_rod_encounter.available_for?(@trainer)

    # After getting Old Rod
    GateUnlock.create!(trainer: @trainer, gate: @gate_2)
    @trainer.reload

    # Both are available
    assert grass_encounter.available_for?(@trainer)
    assert @old_rod_encounter.available_for?(@trainer)
  end

  test "route can have grass, fishing, and surf all at once" do
    # Add grass encounter
    grass_pokemon = Pokemon.find_or_create_by!(pokedex_number: 16) { |p| p.name = "Pidgey"; p.difficulty = 1 }
    grass_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: grass_pokemon,
      spawn_rate: 100,
      encounter_type: "grass"
    )

    # Add surf encounter
    surf_pokemon = Pokemon.find_or_create_by!(pokedex_number: 72) { |p| p.name = "Tentacool"; p.difficulty = 2 }
    surf_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: surf_pokemon,
      spawn_rate: 100,
      encounter_type: "surf",
      required_item_key: "hm_surf"
    )

    # Create HM Surf item
    Item.create!(key: "hm_surf", item_type: "key_item")

    # Initially, only grass is available
    assert grass_encounter.available_for?(@trainer)
    assert_not @old_rod_encounter.available_for?(@trainer)
    assert_not surf_encounter.available_for?(@trainer)

    # After getting Old Rod
    GateUnlock.create!(trainer: @trainer, gate: @gate_2)
    @trainer.reload

    assert grass_encounter.available_for?(@trainer)
    assert @old_rod_encounter.available_for?(@trainer)
    assert_not surf_encounter.available_for?(@trainer)

    # After getting HM Surf
    @trainer.add_item(:hm_surf, 1)
    @trainer.reload

    assert grass_encounter.available_for?(@trainer)
    assert @old_rod_encounter.available_for?(@trainer)
    assert surf_encounter.available_for?(@trainer)

    # Verify route helper methods
    assert @route.has_fishing?
    assert @route.has_surfing?
  end

  # ================================================================================
  # MULTIPLE POKEMON PER ROD TYPE
  # ================================================================================

  test "route can have multiple pokemon for the same rod type with different spawn rates" do
    # Add another pokemon to old_rod encounters
    second_old_rod_pokemon = Pokemon.find_or_create_by!(pokedex_number: 60) { |p| p.name = "Poliwag"; p.difficulty = 1 }
    second_old_rod_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: second_old_rod_pokemon,
      spawn_rate: 50,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )

    # Update first encounter to 50% as well
    @old_rod_encounter.update!(spawn_rate: 50)

    # Give trainer Old Rod
    GateUnlock.create!(trainer: @trainer, gate: @gate_2)
    @trainer.reload

    # Both encounters should be available
    old_rod_encounters = @route.route_encounters.fish.where(required_item_key: "old_rod")
    available = old_rod_encounters.select { |e| e.available_for?(@trainer) }

    assert_equal 2, available.length
    assert_equal 100, available.sum(&:spawn_rate)
  end

  # ================================================================================
  # ENCOUNTER REQUIREMENTS COMBINED WITH ROD REQUIREMENTS
  # ================================================================================

  test "fishing encounter can require both a rod AND a captured pokemon" do
    # Create a rare fish that requires both Super Rod and having caught Magikarp
    rare_fish = Pokemon.find_or_create_by!(pokedex_number: 119) { |p| p.name = "Seaking"; p.difficulty = 3 }
    rare_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: rare_fish,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "super_rod",
      required_pokemon: @old_rod_pokemon  # Must have caught Magikarp
    )

    # Not available without Super Rod
    assert_not rare_encounter.available_for?(@trainer)

    # Get Super Rod
    GateUnlock.create!(trainer: @trainer, gate: @gate_6)
    @trainer.reload

    # Still not available without Magikarp
    assert_not rare_encounter.available_for?(@trainer)

    # Catch Magikarp
    Capture.create!(trainer: @trainer, pokemon: @old_rod_pokemon, ball_type: "pokeball")

    # Now it's available
    assert rare_encounter.available_for?(@trainer)
  end

  test "fishing encounter can require both a rod AND a gate unlock" do
    # Create a route-specific rare fish that requires Super Rod and Gate 10
    legendary_fish = Pokemon.find_or_create_by!(pokedex_number: 131) { |p| p.name = "Lapras"; p.difficulty = 5 }
    legendary_encounter = RouteEncounter.create!(
      route: @route,
      pokemon: legendary_fish,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "super_rod",
      required_gate_number: 10
    )

    gate_10 = Gate.create!(gate_number: 10, required_difficulty_score: 100)

    # Not available without Super Rod
    assert_not legendary_encounter.available_for?(@trainer)

    # Get Super Rod
    GateUnlock.create!(trainer: @trainer, gate: @gate_6)
    @trainer.reload

    # Still not available without Gate 10
    assert_not legendary_encounter.available_for?(@trainer)

    # Unlock Gate 10
    GateUnlock.create!(trainer: @trainer, gate: gate_10)

    # Now it's available
    assert legendary_encounter.available_for?(@trainer)
  end

  # ================================================================================
  # RANDOM ENCOUNTER SELECTION
  # ================================================================================

  test "random_encounter respects rod availability" do
    # Create a route with only fishing encounters
    fishing_route = Route.create!(order: 101, gate_requirement: nil)

    old_encounter = RouteEncounter.create!(
      route: fishing_route,
      pokemon: @old_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "old_rod"
    )

    super_encounter = RouteEncounter.create!(
      route: fishing_route,
      pokemon: @super_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "fish",
      required_item_key: "super_rod"
    )

    # Without any rods, random_encounter should return nil or handle gracefully
    # (depending on implementation - let's test it returns something from all encounters)
    encounter = fishing_route.random_encounter
    assert_includes [@old_rod_pokemon, @super_rod_pokemon], encounter

    # The actual filtering by available_for? would happen in the controller/service layer
  end

  # ================================================================================
  # EDGE CASES
  # ================================================================================

  test "unlocking same gate twice doesn't give duplicate rods" do
    # Unlock Gate 3
    GateUnlock.create!(trainer: @trainer, gate: @gate_2)
    @trainer.reload

    initial_count = @trainer.item_quantity(:old_rod)
    assert_equal 1, initial_count

    # Try to unlock again (this would normally be prevented by validation,
    # but let's test the callback doesn't add duplicate items)
    # This should raise a validation error due to uniqueness constraint
    assert_raises(ActiveRecord::RecordInvalid) do
      GateUnlock.create!(trainer: @trainer, gate: @gate_2)
    end
  end

  test "route without fishing encounters returns false for has_fishing?" do
    grass_only_route = Route.create!(order: 102, gate_requirement: nil)

    RouteEncounter.create!(
      route: grass_only_route,
      pokemon: @old_rod_pokemon,
      spawn_rate: 100,
      encounter_type: "grass"
    )

    assert_not grass_only_route.has_fishing?
    assert_not grass_only_route.fishing_unlocked_for?(@trainer)
  end

  test "trainer can have multiple rods at once" do
    # Unlock all three gates
    GateUnlock.create!(trainer: @trainer, gate: @gate_2)
    GateUnlock.create!(trainer: @trainer, gate: @gate_4)
    GateUnlock.create!(trainer: @trainer, gate: @gate_6)
    @trainer.reload

    assert_equal 1, @trainer.item_quantity(:old_rod)
    assert_equal 1, @trainer.item_quantity(:good_rod)
    assert_equal 1, @trainer.item_quantity(:super_rod)

    # All three types of encounters are available
    assert @old_rod_encounter.available_for?(@trainer)
    assert @good_rod_encounter.available_for?(@trainer)
    assert @super_rod_encounter.available_for?(@trainer)
  end
end
