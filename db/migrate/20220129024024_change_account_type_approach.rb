class ChangeAccountTypeApproach < ActiveRecord::Migration[6.1]
  def change
    remove_column :accounts, :admin, :boolean
    remove_column :accounts, :client, :boolean
    remove_column :accounts, :instructor, :boolean
    remove_column :accounts, :superadmin, :boolean
    add_column :accounts, :ac_type, :string
  end
end
