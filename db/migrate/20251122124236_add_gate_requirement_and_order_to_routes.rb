class AddGateRequirementAndOrderToRoutes < ActiveRecord::Migration[8.1]
  def change
    add_column :routes, :gate_requirement, :integer, null: false, default: 0
    add_column :routes, :order, :integer

    # Backfill order values for existing routes
    reversible do |dir|
      dir.up do
        # Set order based on current id for existing routes
        execute <<-SQL
          UPDATE routes SET "order" = id WHERE "order" IS NULL;
        SQL
      end
    end

    # Now add the not null constraint and unique index
    change_column_null :routes, :order, false
    add_index :routes, :order, unique: true
  end
end
