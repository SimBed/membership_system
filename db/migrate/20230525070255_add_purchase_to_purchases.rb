class AddPurchaseToPurchases < ActiveRecord::Migration[6.1]
  def change
    add_reference :purchases, :purchase, foreign_key: true
  end
end
