class CreatePartyMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :party_members do |t|
      t.references :trainer, null: false, foreign_key: true
      t.references :pokemon, null: false, foreign_key: true
      t.integer :position, null: false

      t.timestamps
    end

    # Each trainer can only use each position once (positions 1-6)
    add_index :party_members, [:trainer_id, :position], unique: true

    # Each trainer can't have the same Pokémon in multiple party slots
    add_index :party_members, [:trainer_id, :pokemon_id], unique: true

    # Ensure position is between 1 and 6
    add_check_constraint :party_members, "position >= 1 AND position <= 6", name: "party_position_range"
  end
end
