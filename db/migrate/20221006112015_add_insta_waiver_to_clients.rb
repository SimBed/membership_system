class AddInstaWaiverToClients < ActiveRecord::Migration[6.1]
  def change
    add_column :clients, :instawaiver, :boolean, default: false
  end
end
