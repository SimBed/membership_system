class CreateStrengthMarkers < ActiveRecord::Migration[7.0]
  def change
    create_table :strength_markers do |t|
      t.string :name
      t.integer :weight
      t.integer :reps
      t.integer :sets
      t.date :date
      t.text :note
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
    add_index :strength_markers, :date
    add_index :strength_markers, :name 
  end
end
