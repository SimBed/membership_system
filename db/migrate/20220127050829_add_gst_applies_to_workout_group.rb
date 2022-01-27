class AddGstAppliesToWorkoutGroup < ActiveRecord::Migration[6.1]
  def change
    add_column :workout_groups, :gst_applies, :boolean, default: true
  end
end
