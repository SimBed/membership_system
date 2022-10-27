class CreateTableDays < ActiveRecord::Migration[6.1]
  def change
    create_table :table_days do |t|
      t.string :name, index: true
      t.string :short_name

      t.timestamps
    end
    add_reference :table_days, :timetable
  end
end
