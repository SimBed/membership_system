class AddInstructorInitialsToWorkouts < ActiveRecord::Migration[6.1]
  def change
    add_column :workouts, :instructor_initials, :boolean, default: false
  end
end
