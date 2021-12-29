class AddFitternityToPurchase < ActiveRecord::Migration[6.1]
  def change
    add_column :purchases, :fitternity_id, :integer
  end
end
