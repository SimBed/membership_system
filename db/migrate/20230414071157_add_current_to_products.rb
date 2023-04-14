class AddCurrentToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :current, :boolean, default: true
    add_index :products, :current
  end
end
