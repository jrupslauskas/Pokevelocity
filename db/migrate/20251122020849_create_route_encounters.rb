class CreateRouteEncounters < ActiveRecord::Migration[8.1]
  def change
    create_table :route_encounters do |t|
      t.references :route, null: false, foreign_key: true
      t.references :pokemon, null: false, foreign_key: true
      t.integer :spawn_rate

      t.timestamps
    end
  end
end
