class AddCurrentToInstructorRates < ActiveRecord::Migration[6.1]
  def change
    add_column :instructor_rates, :current, :boolean, default: true
  end
end
