class RenameAttendancesToBookings < ActiveRecord::Migration[7.0]
  def change
    rename_table :attendances, :bookings
    rename_column :penalties, :attendance_id, :booking_id
  end
end
