class CreateRelWorkoutGroupWorkouts < ActiveRecord::Migration[6.1]
  def change
    create_table :rel_workout_group_workouts do |t|
      t.integer :workout_group_id
      t.integer :workout_id

      t.timestamps
    end
  end
end
