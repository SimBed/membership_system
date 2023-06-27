class CreateChallenges < ActiveRecord::Migration[6.1]
  def change
    create_table :challenges do |t|
      t.string :name
      t.string :metric
      t.string :metric_type
      t.references :challenge, foreign_key: true, index: true

      t.timestamps
    end
    add_index :challenges, :name
  end
end
