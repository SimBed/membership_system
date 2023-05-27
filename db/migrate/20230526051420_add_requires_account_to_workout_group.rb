class AddRequiresAccountToWorkoutGroup < ActiveRecord::Migration[6.1]
  def change
    add_column :workout_groups, :requires_account, :boolean, default: false
    add_column :workout_groups, :service, :string    
    add_index :workout_groups, :service
  end
end
