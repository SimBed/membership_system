class ChangeDiscountToFloat < ActiveRecord::Migration[6.1]
  def change
    change_column :prices, :discount, :float
  end
end
