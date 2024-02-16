class CreateRestarts < ActiveRecord::Migration[7.0]
  def change
    create_table :restarts do |t|
      t.text :note
      t.string :added_by
      t.references :purchase, null: false, foreign_key: true

      t.timestamps
    end
  end
end
