class CreateBodyMarkers < ActiveRecord::Migration[7.0]
  def change
    create_table :body_markers do |t|
      t.string :bodypart
      t.float :measurement
      t.date :date
      t.text :note
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
    add_index :body_markers, :bodypart
    add_index :body_markers, :measurement
    add_index :body_markers, :date
  end
end
