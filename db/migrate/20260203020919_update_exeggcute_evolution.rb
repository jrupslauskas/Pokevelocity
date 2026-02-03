class UpdateExeggcuteEvolution < ActiveRecord::Migration[8.1]
  def up
    exeggcute = Pokemon.find_by(pokedex_number: 102)
    exeggutor = Pokemon.find_by(pokedex_number: 103)

    return unless exeggcute && exeggutor

    # Remove old evolution_stone evolution
    old_evolution = Evolution.find_by(
      from_pokemon: exeggcute,
      to_pokemon: exeggutor,
      required_item_key: "evolution_stone"
    )

    if old_evolution
      old_evolution.destroy!
      Rails.logger.info "Removed old evolution_stone evolution for Exeggcute"
    end

    # Create new leaf_stone evolution
    Evolution.find_or_create_by!(
      from_pokemon: exeggcute,
      to_pokemon: exeggutor,
      required_item_key: "leaf_stone"
    ) do |evo|
      evo.required_item_quantity = 1 # Leaf stones always require 1
    end

    Rails.logger.info "Updated Exeggcute evolution: now uses leaf_stone (quantity: 1)"
  end

  def down
    exeggcute = Pokemon.find_by(pokedex_number: 102)
    exeggutor = Pokemon.find_by(pokedex_number: 103)

    return unless exeggcute && exeggutor

    # Remove leaf_stone evolution
    new_evolution = Evolution.find_by(
      from_pokemon: exeggcute,
      to_pokemon: exeggutor,
      required_item_key: "leaf_stone"
    )

    if new_evolution
      new_evolution.destroy!
      Rails.logger.info "Removed leaf_stone evolution for Exeggcute"
    end

    # Restore evolution_stone evolution
    Evolution.find_or_create_by!(
      from_pokemon: exeggcute,
      to_pokemon: exeggutor,
      required_item_key: "evolution_stone"
    ) do |evo|
      evo.required_item_quantity = [exeggutor.difficulty - 1, 1].max # Should be 2
    end

    Rails.logger.info "Rolled back Exeggcute evolution: restored evolution_stone (quantity: 2)"
  end
end
