class AddRenewableToWorkoutGroup < ActiveRecord::Migration[6.1]
  def change
    add_column :workout_groups, :renewable, :boolean, default: false
  end
end
