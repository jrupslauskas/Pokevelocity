class RemoveDisplayFieldsFromGatesAndRoutes < ActiveRecord::Migration[8.1]
  def change
    # Remove display fields from gates (now loaded from YAML)
    remove_column :gates, :name, :string
    remove_column :gates, :description, :text
    remove_column :gates, :sprite_type, :string
    remove_column :gates, :sprite_value, :string

    # Remove display fields from routes (now loaded from YAML)
    remove_column :routes, :name, :string
    remove_column :routes, :description, :text
  end
end
