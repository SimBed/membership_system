class AddInstaToClients < ActiveRecord::Migration[6.1]
  def change
    add_column :clients, :instagram, :string
  end
end
