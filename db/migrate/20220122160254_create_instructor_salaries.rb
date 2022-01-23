class CreateInstructorSalaries < ActiveRecord::Migration[6.1]
  def change
    create_table :instructor_salaries do |t|
      t.integer :salary
      t.date :date_from
      t.references :instructor, null: false, foreign_key: true

      t.timestamps
    end
  end
end
