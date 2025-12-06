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

    RouteEncounter.find_or_create_by!(route: route, pokemon: pokemon) do |encounter|
      encounter.spawn_rate = encounter_data["spawn_rate"]
    end
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
