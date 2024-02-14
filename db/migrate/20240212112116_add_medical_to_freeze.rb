class AddMedicalToFreeze < ActiveRecord::Migration[7.0]
  def change
    add_column :freezes, :medical, :boolean, default: false
    add_column :freezes, :doctor_note, :boolean, default: false
    add_column :freezes, :added_by, :string
    add_index :freezes, :medical
    add_index :freezes, :doctor_note
  end

end
