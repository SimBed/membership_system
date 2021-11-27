class CreateAttendances < ActiveRecord::Migration[6.1]
  def change
    create_table :attendances do |t|
      t.integer :wkclass_id
      t.integer :rel_user_product_id

      t.timestamps
    end
  end
end
