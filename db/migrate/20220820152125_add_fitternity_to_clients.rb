class AddFitternityToClients < ActiveRecord::Migration[6.1]
  def change
    add_column :clients, :fitternity, :boolean, default: false
  end
end
