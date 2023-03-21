class AddSunsetDateToPurchases < ActiveRecord::Migration[6.1]
  def change
    add_column :purchases, :sunset_date, :date
  end
end
