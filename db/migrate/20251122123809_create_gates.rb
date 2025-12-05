class CreateGates < ActiveRecord::Migration[8.1]
  def change
    create_table :gates do |t|
      t.integer :gate_number, null: false
      t.string :name, null: false
      t.text :description
      t.integer :required_difficulty_score, null: false
      t.string :sprite_type
      t.string :sprite_value

      t.timestamps
    end

    add_index :gates, :gate_number, unique: true
  end
end
