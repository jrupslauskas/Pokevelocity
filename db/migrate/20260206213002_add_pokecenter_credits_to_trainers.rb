class AddPokecenterCreditsToTrainers < ActiveRecord::Migration[8.1]
  def change
    add_column :trainers, :pokecenter_credits, :integer, default: 0, null: false
  end
end
