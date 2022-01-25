class Expense < ApplicationRecord
  belongs_to :workout_group

  def self.by_workout_group(workout_group, start_date, end_date)
      Expense.joins(:workout_group)
             .where("expenses.date BETWEEN '#{start_date}' AND '#{end_date}'")
             .where("workout_groups.name = ?", "#{workout_group}")
  end
end
