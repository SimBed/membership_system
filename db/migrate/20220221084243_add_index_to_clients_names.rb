class AddIndexToClientsNames < ActiveRecord::Migration[6.1]
  def change
    add_index :clients, [:first_name, :last_name]
  end
end
