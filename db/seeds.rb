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

puts "Creating routes..."

# Load routes data from YAML file
routes_data = YAML.load_file(Rails.root.join("db", "data", "routes.yml"))

routes_data.each do |route_data|
  route = Route.find_or_create_by!(name: route_data["name"]) do |r|
    r.description = route_data["description"]
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
