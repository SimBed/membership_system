class RemovePaymentModeFromPurchases < ActiveRecord::Migration[7.0]
  def change
    remove_column :purchases, :payment_mode, :string
  end
end
