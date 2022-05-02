class CreatePenalties < ActiveRecord::Migration[6.1]
  def change
    create_table :penalties do |t|
      t.references :purchase, null: false, foreign_key: true
      t.references :attendance, null: false, foreign_key: true, index: { unique: true }
      t.integer :amount
      t.string :reason

      t.timestamps
    end
  end
end
