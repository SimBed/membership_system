class AddRequiresInvoiceToWorkoutGroup < ActiveRecord::Migration[6.1]
  def change
    add_column :workout_groups, :requires_invoice, :boolean, default: true
  end
end
