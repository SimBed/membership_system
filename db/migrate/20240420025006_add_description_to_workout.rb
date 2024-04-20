class AddDescriptionToWorkout < ActiveRecord::Migration[7.0]
  def change
    add_column :workouts, :description, :text
    add_column :workouts, :styles, :text, array: true, default: []
    add_column :workouts, :level, :string
    add_column :workouts, :warning, :text
  end
end