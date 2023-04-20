class AddClientUiToOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :client_ui, :string, default: nil
    add_index :orders, :client_ui
  end
end
