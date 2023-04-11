class AddInstructorRateToWkclass < ActiveRecord::Migration[6.1]
  def change
    add_column :wkclasses, :instructor_rate_id, :integer
  end
end
