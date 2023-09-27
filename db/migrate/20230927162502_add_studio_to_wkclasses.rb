class AddStudioToWkclasses < ActiveRecord::Migration[7.0]
  def change
    add_column :wkclasses, :studio, :string
    add_column :wkclasses, :duration, :integer
  end
end
