class AddCommissionToInstructor < ActiveRecord::Migration[6.1]
  def change
    add_column :instructors, :commission, :boolean, default: false
  end
end
