class CreateAchievements < ActiveRecord::Migration[6.1]
  def change
    create_table :achievements do |t|
      t.date :date
      t.integer :score
      t.references :challenge, null: false, foreign_key: true, index: true
      t.references :client, null: false, foreign_key: true, index: true

      t.timestamps
    end
    add_index :achievements, :date
    add_index :achievements, :score
  end
end
