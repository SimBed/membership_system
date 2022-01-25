class AddPartnerIdToWorkoutGroup < ActiveRecord::Migration[6.1]
  def change
    add_column :workout_groups, :partner_id, :integer
    add_column :workout_groups, :partner_share, :integer
  end
end
