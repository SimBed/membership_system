class AddCurrentToWorkoutGroups < ActiveRecord::Migration[7.0]
  def change
    add_column :workout_groups, :current, :boolean, default: true
  end
end
