class AddWhatsappGroupToClients < ActiveRecord::Migration[6.1]
  def change
    add_column :clients, :whatsapp_group, :boolean, default: false
  end
end
