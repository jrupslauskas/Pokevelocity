class AddHighContrastModeToTrainers < ActiveRecord::Migration[8.1]
  def change
    add_column :trainers, :high_contrast_mode, :boolean, default: false, null: false
  end
end
