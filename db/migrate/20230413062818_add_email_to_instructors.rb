class AddEmailToInstructors < ActiveRecord::Migration[6.1]
  def change
    add_column :instructors, :email, :string
    add_column :instructors, :whatsapp, :string
    add_reference :instructors, :account, foreign_key: true
  end
end
