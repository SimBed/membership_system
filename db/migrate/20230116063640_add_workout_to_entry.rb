class AddWorkoutToEntry < ActiveRecord::Migration[6.1]
  # def change
  #   add_reference :entries, :workout, null: false, foreign_key: true, default: 1
  #   remove_column :entries, :visibility_switch, :boolean
  # end
  def up
    add_reference :entries, :workout, null: false, foreign_key: true, default: 1
    remove_column :entries, :visibility_switch, :boolean
    hash={"Strength & Conditioning"=> 2, "Pilates Suspension Method"=> 8, "Community WOD"=>19, "Pilates Matwork"=> 20, "Cardio & Skill"=> 28, "Total Body Pump"=> 32, "After Burn"=>31}
    # hash = {"HIIT"=>1, "Pilates Matwork"=>4, "Strength & Conditioning"=>2}
    Entry.all.each { |e| e.update(workout_id: hash.fetch(e.workout, 1)) }
    remove_column :entries, :workout, :string
  end

  def down
    add_column :entries, :workout, :string
    add_column :entries, :visibility_switch, :boolean
    remove_reference :entries, :workout, null: false, foreign_key: true, default: 1
  end
end
