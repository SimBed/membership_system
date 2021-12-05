class CreatePurchases < ActiveRecord::Migration[6.1]
  def change
    create_table :purchases do |t|
      t.integer :client_id
      t.integer :product_id
      t.integer :payment
      t.date :dop
      t.string :payment_mode
      t.string :invoice
      t.text :note
      t.boolean :adjust_restart, default: false
      t.integer :ar_payment
      t.date :ar_date

      t.timestamps
    end
  end
end
