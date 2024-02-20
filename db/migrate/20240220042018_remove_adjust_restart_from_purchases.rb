class RemoveAdjustRestartFromPurchases < ActiveRecord::Migration[7.0]
  def change
    remove_column :purchases, :adjust_restart, :boolean
    remove_column :purchases, :ar_payment, :integer
    remove_column :purchases, :ar_date, :date
    remove_column :purchases, :invoice, :string
  end
end
