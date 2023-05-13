class AddStudentToClients < ActiveRecord::Migration[6.1]
  def change
    add_column :clients, :student, :boolean, default: false
    add_index :clients, :student
    add_column :clients, :friends_and_family, :boolean, default: false
    add_index :clients, :friends_and_family
  end
end
