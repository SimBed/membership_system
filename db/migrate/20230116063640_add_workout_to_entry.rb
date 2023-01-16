class AddWorkoutToEntry < ActiveRecord::Migration[6.1]
  # def change
  #   add_reference :entries, :workout, null: false, foreign_key: true, default: 1
  #   remove_column :entries, :visibility_switch, :boolean
  # end

  # went for an explicit up and down method rather than just a change method as wanted the up to include some code (now deleted) to update workout_id based on the old workout attribute
  def up
    add_reference :entries, :workout, null: false, foreign_key: true, default: 1
    remove_column :entries, :visibility_switch, :boolean
    # hash={"Strength & Conditioning"=> 2, "Pilates Suspension Method"=> 8, "Community WOD"=>19, "Pilates Matwork"=> 20, "Cardio & Skill"=> 28, "Total Body Pump"=> 32, "After Burn"=>31}
    # Entry.all.each { |e| e.update(workout_id: hash.fetch(e.workout, 1)) }
    remove_column :entries, :workout, :string
  end

  def down
    add_column :entries, :workout, :string
    add_column :entries, :visibility_switch, :boolean
    remove_reference :entries, :workout, null: false, foreign_key: true, default: 1
  end
end
