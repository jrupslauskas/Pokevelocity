class AddLengthConstraintToValidationCodeCode < ActiveRecord::Migration[8.1]
  def change
    # Add a check constraint to ensure code is exactly 6 characters
    add_check_constraint :validation_codes, "length(code) = 6", name: "validation_code_length_check"
  end
end
