class CreateRelProductWorkouts < ActiveRecord::Migration[6.1]
  def change
    create_table :rel_product_workouts do |t|
      t.integer :product_id
      t.integer :workout_id

      t.timestamps
    end
  end
end
