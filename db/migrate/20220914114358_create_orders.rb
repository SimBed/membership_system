class CreateOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :orders do |t|
      t.integer :product_id
      t.integer :price
      t.string :status
      t.string :payment_id
      t.integer :account_id

      t.timestamps
    end
  end
end
