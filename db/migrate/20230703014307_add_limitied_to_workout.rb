class AddLimitiedToWorkout < ActiveRecord::Migration[6.1]
  def change
    add_column :workouts, :limited, :boolean, default: true
  end
end
