class CreateGateUnlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :gate_unlocks do |t|
      t.references :trainer, null: false, foreign_key: true
      t.references :gate, null: false, foreign_key: true
      t.datetime :unlocked_at, null: false

      t.timestamps
    end

    add_index :gate_unlocks, [:trainer_id, :gate_id], unique: true
  end
end
