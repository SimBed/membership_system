class CreatePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :payments do |t|
      t.integer :amount
      t.date :dop
      t.string :payment_mode
      t.boolean :online
      t.string :invoice
      t.text :note
      t.integer :payable_id
      t.string :payable_type

      t.timestamps
    end
    add_index :payments, :dop
    add_index :payments, :payment_mode
    add_index :payments, :online
    add_index :payments, [:payable_id, :payable_type]
  end
end
