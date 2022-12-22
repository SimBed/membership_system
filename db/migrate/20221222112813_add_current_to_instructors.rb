class AddCurrentToInstructors < ActiveRecord::Migration[6.1]
  def change
    add_column :instructors, :current, :boolean, default: true
  end
end
