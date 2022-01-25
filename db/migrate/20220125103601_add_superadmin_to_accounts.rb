class AddSuperadminToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :superadmin, :boolean, default: false
  end
end
