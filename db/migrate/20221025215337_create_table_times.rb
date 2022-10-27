class CreateTableTimes < ActiveRecord::Migration[6.1]
  def change
    create_table :table_times do |t|
      t.time :start, index: true

      t.timestamps
    end
    add_reference :table_times, :timetable
  end
end
