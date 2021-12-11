class CreateAdjustments < ActiveRecord::Migration[6.1]
  def change
    create_table :adjustments do |t|
      t.integer :purchase_id
      t.integer :adjustment
      t.text :note

      t.timestamps
    end
  end
end
