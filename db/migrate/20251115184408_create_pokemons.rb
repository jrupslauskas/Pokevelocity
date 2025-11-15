class CreatePokemons < ActiveRecord::Migration[8.1]
  def change
    create_table :pokemons do |t|
      t.integer :pokedex_number, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :pokemons, :pokedex_number, unique: true
  end
end
