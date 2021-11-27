class CreateRelUserProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :rel_user_products do |t|
      t.integer :user_id
      t.integer :product_id
      t.date :dop
      t.integer :payment

      t.timestamps
    end
  end
end
