class AddPriceReferenceToPurchases < ActiveRecord::Migration[6.1]
  def change
    add_reference :purchases, :price, foreign_key: true
  end
end
