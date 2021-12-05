class CreateAttendances < ActiveRecord::Migration[6.1]
  def change
    create_table :attendances do |t|
      t.integer :wkclass_id
      t.integer :purchase_id

      t.timestamps
    end
  end
end
