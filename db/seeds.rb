# Create validation code for new trainers
unless ValidationCode.exists?(code: "PALLET")
  ValidationCode.create!(code: "PALLET", active: true)
  puts "Validation code created: PALLET"
end

puts "Creating Pokémon..."

# Load Pokemon data from YAML file
pokemon_data = YAML.load_file(Rails.root.join("db", "data", "pokemon.yml"))

pokemon_data.each do |data|
  Pokemon.find_or_create_by!(pokedex_number: data["pokedex_number"]) do |pokemon|
    pokemon.name = data["name"]
    pokemon.difficulty = data["difficulty"]
  end
end

puts "Created #{Pokemon.count} Pokémon!"

puts "Creating gates..."

# Load gates data from YAML file
gates_data = YAML.load_file(Rails.root.join("db", "data", "gates.yml"))

gates_data.each do |data|
  gate = Gate.find_or_initialize_by(gate_number: data["gate_number"])
  gate.required_difficulty_score = data["required_difficulty_score"]
  gate.save!
end

puts "Created #{Gate.count} gate(s)!"

puts "Creating routes..."

# Load routes data from YAML file
routes_data = YAML.load_file(Rails.root.join("db", "data", "routes.yml"))

routes_data.each do |route_data|
  route = Route.find_or_create_by!(order: route_data["order"]) do |r|
    r.gate_requirement = route_data["gate_requirement"]
  end

  # Update existing routes with gate_requirement if it's changed
  if route.persisted? && route.gate_requirement != route_data["gate_requirement"]
    route.update!(gate_requirement: route_data["gate_requirement"])
  end

  # Create encounters for this route
  route_data["encounters"].each do |encounter_data|
    pokemon = Pokemon.find_by(name: encounter_data["pokemon"])

    if pokemon.nil?
      puts "  WARNING: Pokemon '#{encounter_data["pokemon"]}' not found, skipping encounter"
      next
    end

    # Find or create the encounter
    encounter = RouteEncounter.find_or_initialize_by(route: route, pokemon: pokemon)
    encounter.spawn_rate = encounter_data["spawn_rate"]

    # Handle required_pokemon
    if encounter_data["required_pokemon"].present?
      required_pokemon = Pokemon.find_by(name: encounter_data["required_pokemon"])
      if required_pokemon
        encounter.required_pokemon_id = required_pokemon.id
      else
        puts "  WARNING: Required Pokemon '#{encounter_data["required_pokemon"]}' not found for #{pokemon.name}"
      end
    else
      encounter.required_pokemon_id = nil
    end

    # Handle alternative_required_pokemon
    if encounter_data["alternative_required_pokemon"].present?
      alternative_pokemon = Pokemon.find_by(name: encounter_data["alternative_required_pokemon"])
      if alternative_pokemon
        encounter.alternative_required_pokemon_id = alternative_pokemon.id
      else
        puts "  WARNING: Alternative required Pokemon '#{encounter_data["alternative_required_pokemon"]}' not found for #{pokemon.name}"
      end
    else
      encounter.alternative_required_pokemon_id = nil
    end

    # Handle required_gate
    if encounter_data["required_gate"].present?
      encounter.required_gate_number = encounter_data["required_gate"]
    else
      encounter.required_gate_number = nil
    end

    encounter.save!
  end

  puts "  #{route.name}: #{route.route_encounters.count} Pokémon"
end

puts "Created #{Route.count} route(s)!"

puts "Creating items..."

# Create items from the Item model constants
Item::ITEMS.each do |item_key, item_data|
  Item.find_or_create_by!(key: item_data[:key]) do |item|
    item.item_type = item_data[:item_type]
  end
end

puts "Created #{Item.count} item(s)!"

puts "Creating evolutions..."

# Load evolution data from YAML file
evolutions_data = YAML.load_file(Rails.root.join("db", "data", "evolutions.yml"))

evolutions_data.each do |evo_data|
  from_pokemon = Pokemon.find_by(pokedex_number: evo_data["from"])
  to_pokemon = Pokemon.find_by(pokedex_number: evo_data["to"])

  if from_pokemon && to_pokemon
    # Calculate required quantity
    # Elemental stones (fire, water, thunder, moon, leaf) and transfer cable always require 1
    # Generic evolution stones use difficulty formula: max(1, to_pokemon.difficulty - 1)
    if ['fire_stone', 'water_stone', 'thunder_stone', 'moon_stone', 'leaf_stone', 'transfer_cable'].include?(evo_data["item"])
      required_quantity = 1
    else
      required_quantity = [to_pokemon.difficulty - 1, 1].max
    end

    evolution = Evolution.find_or_initialize_by(
      from_pokemon_id: from_pokemon.id,
      to_pokemon_id: to_pokemon.id,
      required_item_key: evo_data["item"]
    )
    evolution.required_item_quantity = required_quantity
    evolution.save!
  else
    puts "  WARNING: Could not find Pokemon for evolution #{evo_data["from"]} -> #{evo_data["to"]}"
  end
end

puts "Created #{Evolution.count} evolution(s)!"
