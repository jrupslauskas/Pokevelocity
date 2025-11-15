class CreateTrainers < ActiveRecord::Migration[8.1]
  def change
    create_table :trainers do |t|
      t.string :username, null: false
      t.string :password_digest, null: false
      t.integer :pokeballs_count, default: 0, null: false
      t.integer :great_balls_count, default: 0, null: false
      t.integer :ultra_balls_count, default: 0, null: false
      t.integer :master_balls_count, default: 0, null: false

      t.timestamps
    end

    add_index :trainers, :username, unique: true
  end
end
