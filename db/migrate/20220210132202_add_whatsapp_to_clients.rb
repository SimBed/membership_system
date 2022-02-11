class AddWhatsappToClients < ActiveRecord::Migration[6.1]
  def change
    add_column :clients, :whatsapp, :string
  end
end
