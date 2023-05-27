class AddRiderToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :rider, :boolean, default: false
    add_column :products, :has_rider, :boolean, default: false
    add_index :products, :rider
  end
end
