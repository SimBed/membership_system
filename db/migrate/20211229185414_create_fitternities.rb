class CreateFitternities < ActiveRecord::Migration[6.1]
  def change
    create_table :fitternities do |t|
      t.integer :max_classes
      t.date :expiry_date

      t.timestamps
    end
  end
end
