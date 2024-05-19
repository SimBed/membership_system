class CreateDeclarationUpdates < ActiveRecord::Migration[7.0]
  def change
    create_table :declaration_updates do |t|
      t.date :date
      t.text :note
      t.references :declaration, null: false, foreign_key: true

      t.timestamps
    end
    add_index :declaration_updates, :date
  end
end