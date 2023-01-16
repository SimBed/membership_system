class AddLevelToWkclass < ActiveRecord::Migration[6.1]
  def change
    add_column :wkclasses, :level, :string, default: 'All Levels'
  end
end
