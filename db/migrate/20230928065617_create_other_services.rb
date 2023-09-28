class CreateOtherServices < ActiveRecord::Migration[7.0]
  def change
    create_table :other_services do |t|
      t.string :name
      t.string :link

      t.timestamps
    end
    add_index :other_services, :name
  end
end
