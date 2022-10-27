class CreateEntries < ActiveRecord::Migration[6.1]
  def change
    create_table :entries do |t|
      t.string :workout, index: true
      t.string :subheading1
      t.string :subheading2
      t.string :studio
      t.boolean :visibility_switch, default: false

      t.timestamps
    end
    add_reference :entries, :table_time
    add_reference :entries, :table_day
  end
end
