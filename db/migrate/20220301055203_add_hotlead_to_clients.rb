class AddHotleadToClients < ActiveRecord::Migration[6.1]
  def change
    add_column :clients, :hotlead, :boolean, default: false
  end
end
