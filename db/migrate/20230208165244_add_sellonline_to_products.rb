class AddSellonlineToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :sellonline, :boolean, default: false
  end
end
