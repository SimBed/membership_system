class AddNoInstructorToInstructors < ActiveRecord::Migration[6.1]
  def change
    add_column :instructors, :no_instructor, :boolean, default:false
    add_index :instructors, :no_instructor
  end
end
