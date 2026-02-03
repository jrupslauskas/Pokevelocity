class RemoveEeveeFromRoutes < ActiveRecord::Migration[8.1]
  def up
    # Find Eevee
    eevee = Pokemon.find_by(pokedex_number: 133)
    return unless eevee

    # Route 22: Celadon City - Game Corner
    route_22 = Route.find_by(order: 22)
    if route_22
      # Remove Eevee encounter
      RouteEncounter.where(route: route_22, pokemon: eevee).destroy_all

      # Update spawn rates for remaining Pokemon
      update_spawn_rate(route_22, "Abra", 20)
      update_spawn_rate(route_22, "Clefairy", 20)
    end

    # Route 48: Professor Oak's Back Forty
    route_48 = Route.find_by(order: 48)
    if route_48
      # Remove Eevee encounter
      RouteEncounter.where(route: route_48, pokemon: eevee).destroy_all

      # Update spawn rates for remaining Pokemon
      update_spawn_rate(route_48, "Bulbasaur", 25)
      update_spawn_rate(route_48, "Squirtle", 25)
      update_spawn_rate(route_48, "Charmander", 25)
      update_spawn_rate(route_48, "Pikachu", 25)
    end

    # Route 29: Safari Zone - Area 2 (spawn rate adjustments)
    route_29 = Route.find_by(order: 29)
    if route_29
      update_spawn_rate(route_29, "Nidoran♂", 25)
      update_spawn_rate(route_29, "Rhyhorn", 10)
    end

    Rails.logger.info "Successfully removed Eevee from routes 22 and 48, updated spawn rates"
  end

  def down
    # Find Eevee
    eevee = Pokemon.find_by(pokedex_number: 133)
    return unless eevee

    # Route 22: Restore Eevee encounter
    route_22 = Route.find_by(order: 22)
    if route_22
      RouteEncounter.find_or_create_by!(
        route: route_22,
        pokemon: eevee,
        encounter_type: "grass"
      ) do |encounter|
        encounter.spawn_rate = 10
      end

      # Restore original spawn rates
      update_spawn_rate(route_22, "Abra", 15)
      update_spawn_rate(route_22, "Clefairy", 15)
    end

    # Route 48: Restore Eevee encounter
    route_48 = Route.find_by(order: 48)
    if route_48
      RouteEncounter.find_or_create_by!(
        route: route_48,
        pokemon: eevee,
        encounter_type: "grass"
      ) do |encounter|
        encounter.spawn_rate = 20
      end

      # Restore original spawn rates
      update_spawn_rate(route_48, "Bulbasaur", 20)
      update_spawn_rate(route_48, "Squirtle", 20)
      update_spawn_rate(route_48, "Charmander", 20)
      update_spawn_rate(route_48, "Pikachu", 20)
    end

    # Route 29: Restore original spawn rates
    route_29 = Route.find_by(order: 29)
    if route_29
      update_spawn_rate(route_29, "Nidoran♂", 30)
      update_spawn_rate(route_29, "Rhyhorn", 5)
    end

    Rails.logger.info "Rolled back: Re-added Eevee to routes 22 and 48, restored spawn rates"
  end

  private

  def update_spawn_rate(route, pokemon_name, new_rate)
    pokemon = Pokemon.find_by(name: pokemon_name)
    return unless pokemon

    encounter = RouteEncounter.find_by(route: route, pokemon: pokemon)
    if encounter
      encounter.update!(spawn_rate: new_rate)
    else
      Rails.logger.warn "Pokemon #{pokemon_name} not found on route #{route.order}"
    end
  end
end
