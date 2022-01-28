class AddAccountIdToClients < ActiveRecord::Migration[6.1]
  def change
    add_column :clients, :account_id, :integer
    add_column :clients, :note, :text
  end
end
