class CreateValidationCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :validation_codes do |t|
      t.string :code
      t.boolean :active

      t.timestamps
    end
  end
end
