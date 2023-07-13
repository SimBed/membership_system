class AddLimitedToWorkouts < ActiveRecord::Migration[6.1]
  def change
    add_column :workouts, :limited, :boolean, default: true
    add_column :workouts, :default_capacity, :integer, default: 12
  end
end
