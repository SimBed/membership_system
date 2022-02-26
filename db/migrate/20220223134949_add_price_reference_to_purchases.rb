class AddPriceReferenceToPurchases < ActiveRecord::Migration[6.1]
  def change
    # add_reference :purchases, :price, foreign_key: true
    add_column :purchases, :price_id, :integer
    add_index :purchases, :price_id
  end
end
