require 'test_helper'

class Admin::EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @entry = entries(:one)
    @table_day = table_days(:one)
    @table_time = table_times(:one)
    @admin = accounts(:admin)
    @workout = workouts(:hiit)
  end

  test 'should get new' do
    log_in_as(@admin)
    get new_entry_url

    assert_response :success
  end

  test 'should create entry' do
    log_in_as(@admin)
    assert_difference('Entry.count') do
      post entries_url, params: {
        entry: {
          studio: @entry.studio,
          goal: @entry.goal,
          level: @entry.level,
          workout_id: @workout.id,
          table_day_id: @table_day.id,
          table_time_id: @table_time.id
        }
      }
    end

    assert_redirected_to timetable_url(@table_day.timetable)
  end

  test 'should get edit' do
    log_in_as(@admin)
    get edit_entry_url(@entry)

    assert_response :success
  end

  test 'should update entry' do
    log_in_as(@admin)
    patch entry_url(@entry), params: { entry: { studio: @entry.studio, goal: @entry.goal, level: @entry.level, workout_id: 4 } }

    assert_redirected_to timetable_url(@entry.table_day.timetable)
  end

  test 'should destroy entry' do
    log_in_as(@admin)
    timetable = @entry.table_day.timetable
    assert_difference('Entry.count', -1) do
      delete entry_url(@entry)
    end

    assert_redirected_to timetable_url(timetable)
  end
end
