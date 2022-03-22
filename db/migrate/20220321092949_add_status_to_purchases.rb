class AddStatusToPurchases < ActiveRecord::Migration[6.1]
  def change
    add_column :purchases, :status, :string, default: 'not started'
    add_column :purchases, :expiry_date, :date
    add_column :purchases, :start_date, :date
    add_column :purchases, :tax_included, :boolean, default: 'true'

    add_index :purchases, :status, name: 'purchases_status_index'

    remove_column :purchases, :expired
  end
end
