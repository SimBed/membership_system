class Expense < ApplicationRecord
  belongs_to :workout_group
  scope :order_by_date, -> { order(date: :desc) }
  scope :during, ->(period) { where({ date: period }) }

  def self.by_workout_group(workout_group, period)
    joins(:workout_group)
      .where("expenses.date BETWEEN '#{period.begin}' AND '#{period.end}'")
      .where(workout_groups: { name: workout_group.to_s })
  end
end
