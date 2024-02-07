class AddEmployeeToInstructors < ActiveRecord::Migration[7.0]
  def change
    add_column :instructors, :employee, :boolean, default: true
  end
end
