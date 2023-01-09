class AddDurationToEntries < ActiveRecord::Migration[6.1]
  def change
    add_column :entries, :duration, :integer, default: 60
    rename_column :entries, :subheading1, :goal
    rename_column :entries, :subheading2, :level
  end
end
