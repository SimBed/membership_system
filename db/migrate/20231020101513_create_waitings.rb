class CreateWaitings < ActiveRecord::Migration[7.0]
  def change
    create_table :waitings do |t|
      t.references :wkclass, null: false, foreign_key: true
      t.references :purchase, null: false, foreign_key: true

      t.timestamps
    end
  end
end
