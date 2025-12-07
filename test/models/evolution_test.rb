require "test_helper"

class EvolutionTest < ActiveSupport::TestCase
  test "should belong to from_pokemon" do
    evolution = evolutions(:pikachu_to_raichu)
    assert_equal pokemons(:pikachu), evolution.from_pokemon
  end

  test "should belong to to_pokemon" do
    evolution = evolutions(:pikachu_to_raichu)
    assert_equal pokemons(:raichu), evolution.to_pokemon
  end

  test "should require from_pokemon_id" do
    evolution = Evolution.new(
      to_pokemon: pokemons(:raichu),
      required_item_key: 'thunder_stone',
      required_item_quantity: 1
    )
    assert_not evolution.valid?
    assert_includes evolution.errors[:from_pokemon_id], "can't be blank"
  end

  test "should require to_pokemon_id" do
    evolution = Evolution.new(
      from_pokemon: pokemons(:pikachu),
      required_item_key: 'thunder_stone',
      required_item_quantity: 1
    )
    assert_not evolution.valid?
    assert_includes evolution.errors[:to_pokemon_id], "can't be blank"
  end

  test "should require required_item_key" do
    evolution = Evolution.new(
      from_pokemon: pokemons(:pikachu),
      to_pokemon: pokemons(:raichu),
      required_item_quantity: 1
    )
    assert_not evolution.valid?
    assert_includes evolution.errors[:required_item_key], "can't be blank"
  end

  test "should require required_item_quantity" do
    evolution = Evolution.new(
      from_pokemon: pokemons(:pikachu),
      to_pokemon: pokemons(:raichu),
      required_item_key: 'thunder_stone'
    )
    assert_not evolution.valid?
    assert_includes evolution.errors[:required_item_quantity], "can't be blank"
  end

  test "required_item_quantity must be greater than 0" do
    evolution = Evolution.new(
      from_pokemon: pokemons(:pikachu),
      to_pokemon: pokemons(:raichu),
      required_item_key: 'thunder_stone',
      required_item_quantity: 0
    )
    assert_not evolution.valid?
    assert_includes evolution.errors[:required_item_quantity], "must be greater than 0"
  end

  test "should allow multiple evolutions from same pokemon" do
    eevee = pokemons(:eevee)
    eevee_evolutions = Evolution.where(from_pokemon: eevee)
    assert_equal 2, eevee_evolutions.count
    assert_includes eevee_evolutions.map(&:to_pokemon), pokemons(:vaporeon)
    assert_includes eevee_evolutions.map(&:to_pokemon), pokemons(:jolteon)
  end

  test "should get required_item" do
    evolution = evolutions(:pikachu_to_raichu)
    item = evolution.required_item
    assert_not_nil item
    assert_equal 'thunder_stone', item.key
  end

  test "can_trainer_evolve? returns true when trainer has enough items" do
    trainer = trainers(:ash)
    evolution = evolutions(:pikachu_to_raichu)

    # Give trainer enough thunder stones (elemental stones only need 1)
    thunder_stone = items(:thunder_stone)
    trainer.trainer_items.create!(item: thunder_stone, quantity: 1)

    assert evolution.can_trainer_evolve?(trainer)
  end

  test "can_trainer_evolve? returns false when trainer doesn't have enough items" do
    trainer = trainers(:ash)
    evolution = evolutions(:wartortle_to_blastoise) # requires 3 evolution stones

    # Give trainer only 2 evolution stones (not enough)
    evolution_stone = items(:evolution_stone)
    trainer.trainer_items.create!(item: evolution_stone, quantity: 2)

    assert_not evolution.can_trainer_evolve?(trainer)
  end

  test "can_trainer_evolve? returns false when trainer has no items" do
    trainer = trainers(:ash)
    evolution = evolutions(:pikachu_to_raichu)

    assert_not evolution.can_trainer_evolve?(trainer)
  end

  test "evolution chain works correctly" do
    squirtle_to_wartortle = evolutions(:squirtle_to_wartortle)
    wartortle_to_blastoise = evolutions(:wartortle_to_blastoise)

    # Squirtle evolves to Wartortle
    assert_equal pokemons(:squirtle), squirtle_to_wartortle.from_pokemon
    assert_equal pokemons(:wartortle), squirtle_to_wartortle.to_pokemon
    assert_equal 2, squirtle_to_wartortle.required_item_quantity

    # Wartortle evolves to Blastoise
    assert_equal pokemons(:wartortle), wartortle_to_blastoise.from_pokemon
    assert_equal pokemons(:blastoise), wartortle_to_blastoise.to_pokemon
    assert_equal 3, wartortle_to_blastoise.required_item_quantity
  end
end
