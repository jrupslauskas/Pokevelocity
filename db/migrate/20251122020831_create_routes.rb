class CreateRoutes < ActiveRecord::Migration[8.1]
  def change
    create_table :routes do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
