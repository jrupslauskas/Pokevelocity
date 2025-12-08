class AddAppearanceRequirementsToRouteEncounters < ActiveRecord::Migration[8.1]
  def change
    add_column :route_encounters, :required_pokemon_id, :integer
    add_column :route_encounters, :required_gate_number, :integer

    add_foreign_key :route_encounters, :pokemons, column: :required_pokemon_id
    add_index :route_encounters, :required_pokemon_id
    add_index :route_encounters, :required_gate_number
  end
end
