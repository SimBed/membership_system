class AddDiscountToPrices < ActiveRecord::Migration[6.1]
  def change
    add_column :prices, :discount, :integer, default: 0
    add_column :prices, :base, :boolean, default: false
    add_column :prices, :renewal_pre_expiry, :boolean, default: false
    add_column :prices, :renewal_pretrial_expiry, :boolean, default: false
    add_column :prices, :renewal_posttrial_expiry, :boolean, default: false

    add_index :prices, :base
    add_index :prices, :renewal_pre_expiry
    add_index :prices, :renewal_pretrial_expiry
    add_index :prices, :renewal_posttrial_expiry
  end
end
