class RemoveInstructorIdFromWorkouts < ActiveRecord::Migration[6.1]
  def change
    remove_column :workouts, :instructor_id, :integer
  end
end
