class AddAmnestyToAttendances < ActiveRecord::Migration[6.1]
  def change
    add_column :attendances, :amnesty, :boolean, default: false
  end
end
