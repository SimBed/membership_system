class RemovePartnerFromWorkoutGroup < ActiveRecord::Migration[7.0]
  def change
    remove_column :workout_groups, :partner_id, :integer
    remove_column :workout_groups, :partner_share, :integer
    remove_column :workout_groups, :gst_applies, :boolean
    remove_column :workout_groups, :requires_invoice, :boolean
  end
end