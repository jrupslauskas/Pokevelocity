class MakeGateRequirementNullableOnRoutes < ActiveRecord::Migration[8.1]
  def change
    change_column_null :routes, :gate_requirement, true
    change_column_default :routes, :gate_requirement, from: 0, to: nil
  end
end
