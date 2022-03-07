require 'test_helper'

class ExpenseTest < ActiveSupport::TestCase
  def setup
    @expense = Expense.new(item: 'zoom',
                           amount: 1000,
                           date: '2022-02-01',
                           workout_group_id: ActiveRecord::FixtureSet.identify(:space))
  end

  test 'should be valid' do
    assert @expense.valid?
  end

  test 'workout_group should be valid' do
    @expense.workout_group_id = 21
    refute @expense.valid?
  end
end
