class AddDifficultyToPokemon < ActiveRecord::Migration[8.1]
  def change
    add_column :pokemons, :difficulty, :integer, default: 3, null: false
  end
end
