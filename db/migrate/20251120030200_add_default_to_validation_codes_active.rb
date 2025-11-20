class AddDefaultToValidationCodesActive < ActiveRecord::Migration[8.1]
  def change
    change_column_default :validation_codes, :active, from: nil, to: true
  end
end
