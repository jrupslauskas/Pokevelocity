class AddIconPokemonToTrainers < ActiveRecord::Migration[8.1]
  def change
    add_column :trainers, :icon_pokemon_id, :integer
  end
end
