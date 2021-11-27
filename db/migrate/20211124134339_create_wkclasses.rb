class CreateWkclasses < ActiveRecord::Migration[6.1]
  def change
    create_table :wkclasses do |t|
      t.integer :workout_id
      t.datetime :start_time

      t.timestamps
    end
  end
end
