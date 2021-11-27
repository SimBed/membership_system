class CreateProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :products do |t|
      t.integer :max_classes
      t.integer :validity_length

      t.timestamps
    end
  end
end
