class AddExpiredToPurchases < ActiveRecord::Migration[6.1]
  def change
    add_column :purchases, :expired, :boolean, default: false
  end
end
