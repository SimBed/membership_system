class Expense < ApplicationRecord
  include Csv
  belongs_to :workout_group
  scope :order_by_date, -> { order(date: :desc) }
  scope :during, ->(period) { where({ date: period }) }
  validates :item, presence: true
  validates :amount, presence: true
  validate :unique_expense

  def self.by_workout_group(workout_group, period)
    joins(:workout_group)
      .where("expenses.date BETWEEN '#{period.begin}' AND '#{period.end}'")
      .where(workout_groups: { name: workout_group.to_s })
  end

  private

  def unique_expense
    expense = Expense.where(['item = ? and amount = ? and date = ? and workout_group_id = ?', item, amount,
                             date, workout_group_id]).first
    return if expense.blank?

    errors.add(:base, 'This Expense has already been added to this workout group for this period') unless id == expense.id
  end
end
