require 'test_helper'

class Admin::EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @entry = entries(:entry1)
    @table_day = table_days(:mon1)
    @table_time = table_times(:one)
    @admin = accounts(:admin)
    @workout = workouts(:hiit)
    @workout_other = workouts(:mobility)
  end

  test 'should get new' do
    log_in_as(@admin)
    get new_entry_path

    assert_response :success
  end

  test 'should create entry' do
    log_in_as(@admin)
    assert_difference('Entry.count') do
      post entries_path, params: {
        entry: {
          studio: 'cellar',
          goal: 'entropy',
          level: 'prime',
          workout_id: @workout.id,
          table_day_id: @table_day.id,
          table_time_id: @table_time.id
        }
      }
    end

    assert_redirected_to timetable_path(@table_day.timetable)
  end

  test 'should get edit' do
    log_in_as(@admin)
    get edit_entry_path(@entry)

    assert_response :success
  end

  test 'should update entry' do
    log_in_as(@admin)
    patch entry_path(@entry), params: { entry: { studio: 'window', goal: 'skill', level: 'olympic', workout_id: @workout_other.id } }

    assert_redirected_to timetable_path(@entry.table_day.timetable)
  end

  test 'should destroy entry' do
    log_in_as(@admin)
    timetable = @entry.table_day.timetable
    assert_difference('Entry.count', -1) do
      delete entry_path(@entry)
    end

    assert_redirected_to timetable_path(timetable)
  end
end
