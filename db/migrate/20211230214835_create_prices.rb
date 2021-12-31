class CreatePrices < ActiveRecord::Migration[6.1]
  def change
    create_table :prices do |t|
      t.integer :price
      t.date :date_from
      t.integer :product_id

      t.timestamps
    end
  end
end
