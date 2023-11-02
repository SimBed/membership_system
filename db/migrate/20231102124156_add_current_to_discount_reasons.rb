class AddCurrentToDiscountReasons < ActiveRecord::Migration[7.0]
  def change
    add_column :discount_reasons, :current, :boolean, default: true
    add_index :discount_reasons, :current
  end
end
