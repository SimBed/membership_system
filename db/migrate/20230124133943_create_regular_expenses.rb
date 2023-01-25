class CreateRegularExpenses < ActiveRecord::Migration[6.1]
  def change
    create_table :regular_expenses do |t|
      t.string :item
      t.integer :amount
      t.references :workout_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
