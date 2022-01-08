class CreatePrices < ActiveRecord::Migration[6.1]
  def change
    create_table :prices do |t|
      t.string :name
      t.integer :price
      t.date :date_from
      t.boolean :current
      t.integer :product_id

      t.timestamps
    end
  end
end
