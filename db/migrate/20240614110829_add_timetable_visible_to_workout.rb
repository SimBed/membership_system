class AddTimetableVisibleToWorkout < ActiveRecord::Migration[7.0]
  def change
    add_column :workouts, :public_timetable_visible, :boolean, default: true
  end
end