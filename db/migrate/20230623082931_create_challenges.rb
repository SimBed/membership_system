class CreateChallenges < ActiveRecord::Migration[6.1]
  def change
    create_table :challenges do |t|
      t.string :name
      t.string :metric
      t.string :metric_type

      t.timestamps
    end
    add_index :challenges, :name
  end
end
