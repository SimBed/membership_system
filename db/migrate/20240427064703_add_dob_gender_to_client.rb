class AddDobGenderToClient < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :dob, :date
    add_column :clients, :gender, :string
        
    add_index :clients, :dob
    add_index :clients, :gender
  end
end
