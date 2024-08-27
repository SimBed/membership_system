require 'test_helper'

class TimetableTest < ActiveSupport::TestCase

  def setup
    # set test date at end of 1 timetable period so new timetable will kick in shortly
    @timetable_may = timetables(:may22)
    @test_date = @timetable_may.date_from.advance(days: -3)
    travel_to(@test_date.beginning_of_day)
  end

  test 'class method entries_hash' do
    assert_equal Timetable.display_entries['Saturday'][1], entries(:entry_sat_1030_march)
    assert_equal Timetable.display_entries['Monday'][0], entries(:entry_mon_0900_april)
  end
end
