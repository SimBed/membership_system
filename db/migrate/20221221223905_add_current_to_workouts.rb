class AddCurrentToWorkouts < ActiveRecord::Migration[6.1]
  def change
    add_column :workouts, :current, :boolean, default: true
  end
end
