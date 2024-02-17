class CreateRestarts < ActiveRecord::Migration[7.0]
  def change
    create_table :restarts do |t|
      t.text :note
      t.string :added_by
      t.references :parent
      t.references :child

      t.timestamps
    end
    add_foreign_key :restarts, :purchases, column: :parent_id
    add_foreign_key :restarts, :purchases, column: :child_id
  end
end

