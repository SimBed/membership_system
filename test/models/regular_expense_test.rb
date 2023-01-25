require "test_helper"

class RegularExpenseTest < ActiveSupport::TestCase
  def setup
    @regular_expense = RegularExpense.new(
                           item: 'chapati',
                           amount: 100,
                           workout_group_id: workout_groups(:space).id)
  end

  test 'should be valid' do
    assert_predicate @regular_expense, :valid?
  end

  test 'workout_group should be valid' do
    @regular_expense.workout_group_id = 4000
    refute_predicate @regular_expense, :valid?
  end

end
