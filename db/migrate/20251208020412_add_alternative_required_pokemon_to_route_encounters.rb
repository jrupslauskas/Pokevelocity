class AddAlternativeRequiredPokemonToRouteEncounters < ActiveRecord::Migration[8.1]
  def change
    add_column :route_encounters, :alternative_required_pokemon_id, :integer
    add_foreign_key :route_encounters, :pokemons, column: :alternative_required_pokemon_id
    add_index :route_encounters, :alternative_required_pokemon_id
  end
end
