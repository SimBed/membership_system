class AddBookingsToAttendances < ActiveRecord::Migration[6.1]
  def change
    add_column :attendances, :status, :string, default: 'booked'
    add_column :attendances, :booked_by, :string
    add_column :attendances, :cancellation_count, :integer, default: 0
  end
end
