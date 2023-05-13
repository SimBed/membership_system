class CreateDiscounts < ActiveRecord::Migration[6.1]
  def change
    create_table :discounts do |t|
      t.references :discount_reason, null: false, foreign_key: true      
      t.float :percent
      t.integer :fixed, default: nil
      t.boolean :group, default: true
      t.boolean :pt, default: false
      t.boolean :online, default: false
      t.boolean :aggregatable, default: false      
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
    add_index :discounts, :group
    add_index :discounts, :pt
    add_index :discounts, :online
    add_index :discounts, :start_date
    add_index :discounts, :end_date
  end
end
