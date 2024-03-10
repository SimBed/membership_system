class RenamePaymentToChargeInPurchases < ActiveRecord::Migration[7.0]
  def change
    rename_column :purchases, :payment, :charge
  end
end
