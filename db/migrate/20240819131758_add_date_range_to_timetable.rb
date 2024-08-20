class AddDateRangeToTimetable < ActiveRecord::Migration[7.0]
  def change
    add_column :timetables, :date_from, :date
    add_column :timetables, :date_until, :date
  end
end
