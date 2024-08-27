require 'test_helper'

class Admin::TableTimesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @table_time = table_times(:one)
    @timetable = timetables(:mar22)
    @admin = accounts(:admin)
  end

  test 'should get new' do
    log_in_as(@admin)
    get new_table_time_path

    assert_response :success
  end

  test 'should create table_time' do
    log_in_as(@admin)
    assert_difference('TableTime.count') do
      post table_times_path, params: {
        table_time: {
          start: '2000-01-01 20:00:00',
          timetable_id: @timetable.id
        }
      }
    end

    assert_redirected_to timetable_path(@timetable)
  end

  test 'should get edit' do
    log_in_as(@admin)
    get edit_table_time_path(@table_time)

    assert_response :success
  end

  test 'should update table_time' do
    log_in_as(@admin)
    patch table_time_path(@table_time), params: { table_time: { start: '2000-01-01 20:00:00' } }

    assert_redirected_to timetable_path(@timetable)
  end

  test 'should destroy table_time' do
    log_in_as(@admin)
    assert_difference('TableTime.count', -1) do
      delete table_time_path(@table_time)
    end

    assert_redirected_to timetable_path(@timetable)
  end
end
