class AddNoshowsToPurchases < ActiveRecord::Migration[6.1]
  def change
    add_column :purchases, :early_cancels, :integer, default: 0
    add_column :purchases, :late_cancels, :integer, default: 0
    add_column :purchases, :no_shows, :integer, default: 0
  end
end
