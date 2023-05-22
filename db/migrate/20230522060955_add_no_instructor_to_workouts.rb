class AddNoInstructorToWorkouts < ActiveRecord::Migration[6.1]
  def change
    add_column :workouts, :no_instructor, :boolean, default:false
  end
end
