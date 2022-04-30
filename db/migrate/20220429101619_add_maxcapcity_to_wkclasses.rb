class AddMaxcapcityToWkclasses < ActiveRecord::Migration[6.1]
  def change
    add_column :wkclasses, :max_capacity, :integer
  end
end
