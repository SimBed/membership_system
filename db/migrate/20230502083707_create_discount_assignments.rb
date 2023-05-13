class CreateDiscountAssignments < ActiveRecord::Migration[6.1]
  def change
    create_table :discount_assignments do |t|
      t.references :discount, null: false, foreign_key: true
      t.references :purchase, null: false, foreign_key: true

      t.timestamps
    end
  end
end
