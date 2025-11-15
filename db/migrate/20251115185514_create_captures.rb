class CreateCaptures < ActiveRecord::Migration[8.1]
  def change
    create_table :captures do |t|
      t.references :trainer, null: false, foreign_key: true
      t.references :pokemon, null: false, foreign_key: true
      t.string :ball_type, null: false
      t.datetime :captured_at, null: false

      t.timestamps
    end

    add_index :captures, [:trainer_id, :pokemon_id], unique: true
  end
end
