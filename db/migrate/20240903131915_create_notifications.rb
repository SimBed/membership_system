class CreateNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :notifications do |t|
      t.datetime :read_at
      t.references :account, null: false, foreign_key: true
      t.references :announcement, null: false, foreign_key: true

      t.timestamps
    end
  end
end
