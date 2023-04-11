class AddNameToInstructorRates < ActiveRecord::Migration[6.1]
  def change
    add_column :instructor_rates, :group, :boolean
    add_index :instructor_rates, :group
    add_column :instructor_rates, :name, :string
    add_index :instructor_rates, :name
  end
end
