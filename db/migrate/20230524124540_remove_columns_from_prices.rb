class RemoveColumnsFromPrices < ActiveRecord::Migration[6.1]
  def change
    remove_column :prices, :name, :string
    remove_column :prices, :current, :boolean
    remove_column :prices, :discount, :float
    remove_column :prices, :renewal_pre_expiry, :boolean
    remove_column :prices, :renewal_pretrial_expiry, :boolean
    remove_column :prices, :renewal_posttrial_expiry, :boolean
    remove_column :prices, :base, :boolean
  end
end
