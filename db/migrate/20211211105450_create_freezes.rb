class CreateFreezes < ActiveRecord::Migration[6.1]
  def change
    create_table :freezes do |t|
      t.integer :purchase_id
      t.date :start_date
      t.date :end_date
      t.text :note

      t.timestamps
    end
  end
end
