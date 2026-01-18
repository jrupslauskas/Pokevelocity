class AddAdventureLimitToTrainers < ActiveRecord::Migration[8.1]
  def change
    add_column :trainers, :adventures_remaining, :integer, default: 5, null: false
    add_column :trainers, :adventures_allocated_at, :datetime

    # Initialize existing trainers with current timestamp
    reversible do |dir|
      dir.up do
        Trainer.update_all(adventures_allocated_at: Time.current)
      end
    end
  end
end
