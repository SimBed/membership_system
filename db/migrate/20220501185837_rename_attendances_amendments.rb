class RenameAttendancesAmendments < ActiveRecord::Migration[6.1]
  def change
    rename_column :attendances, :cancellation_count, :amendment_count
  end
end
