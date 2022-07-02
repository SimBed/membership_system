class AddWhatsappToPartners < ActiveRecord::Migration[6.1]
  def change
    add_column :partners, :whatsapp, :string
    add_column :partners, :instagram, :string
  end
end
