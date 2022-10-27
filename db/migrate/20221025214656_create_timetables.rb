class CreateTimetables < ActiveRecord::Migration[6.1]
  def change
    create_table :timetables do |t|
      t.string :title, index: true

      t.timestamps
    end
  end
end
