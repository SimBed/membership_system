class CreateProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :products do |t|
      t.integer :max_classes
      t.integer :validity_length
      t.string :validity_unit
      t.integer :workout_group_id

      t.timestamps
    end
  end
end
