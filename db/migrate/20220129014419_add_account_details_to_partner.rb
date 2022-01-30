class AddAccountDetailsToPartner < ActiveRecord::Migration[6.1]
  def change
    add_column :partners, :account_id, :integer
    add_column :partners, :email, :string
    add_column :partners, :phone, :string
  end
end
