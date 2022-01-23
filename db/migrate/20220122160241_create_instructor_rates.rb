class CreateInstructorRates < ActiveRecord::Migration[6.1]
  def change
    create_table :instructor_rates do |t|
      t.integer :rate
      t.date :date_from
      t.references :instructor, null: false, foreign_key: true

      t.timestamps
    end
  end
end
