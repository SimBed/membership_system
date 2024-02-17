class AddRestartParentToPurchases < ActiveRecord::Migration[7.0]
  def change
    # add_reference :purchases, :restart_parent, references: :purchase, foreign_key: true
    # https://stackoverflow.com/questions/13694654/specifying-column-name-in-a-references-migration @jess5199 [not relevant in the end]
    # add_reference :purchases, :restart_parent
    # add_reference :purchases, :restart_child
  end
end
