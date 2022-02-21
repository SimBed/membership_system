class AddEfficiencyIndices < ActiveRecord::Migration[6.1]
  def change
    add_index :purchases, :dop
    add_index :purchases, :expired
    add_index :purchases, :product_id
    add_index :purchases, :client_id
    add_index :wkclasses, :start_time
    add_index :wkclasses, :workout_id
    add_index :wkclasses, :instructor_id
    add_index :attendances, :wkclass_id
    add_index :attendances, :purchase_id
    add_index :attendances, :status
    add_index :clients, :account_id
    add_index :clients, [:first_name, :last_name]
    add_index :adjustments, :purchase_id
    add_index :expenses, :amount
    add_index :freezes, :purchase_id
    add_index :partners, :account_id
    add_index :prices, :product_id
    add_index :products, :max_classes
    add_index :rel_workout_group_workouts, :workout_group_id
    add_index :rel_workout_group_workouts, :workout_id
    add_index :workout_groups, :name
    add_index :workouts, :name
  end
end
