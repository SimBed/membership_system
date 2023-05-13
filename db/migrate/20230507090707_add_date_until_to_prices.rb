class AddDateUntilToPrices < ActiveRecord::Migration[6.1]
  def change
    add_column :prices, :date_until, :date
    add_index :prices, :date_from
    add_index :prices, :date_until
  end
end
