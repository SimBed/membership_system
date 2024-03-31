class RemoveAcTypeFromAccounts < ActiveRecord::Migration[7.0]
  def change
    remove_column :accounts, :ac_type, :string
  end
end
