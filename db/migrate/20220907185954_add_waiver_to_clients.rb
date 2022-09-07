class AddWaiverToClients < ActiveRecord::Migration[6.1]
  def change
    add_column :clients, :waiver, :boolean, default: false
  end
end
