require 'test_helper'

class Admin::TableTimesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @table_time = table_times(:one)
    @timetable = timetables(:publictim)
    @admin = accounts(:admin)
  end

  test 'should get new' do
    log_in_as(@admin)
    get new_admin_table_time_url

    assert_response :success
  end

  test 'should create table_time' do
    log_in_as(@admin)
    assert_difference('TableTime.count') do
      post admin_table_times_url, params: {
        table_time: {
          start: @table_time.start,
          timetable_id: @timetable.id
        }
      }
    end

    assert_redirected_to admin_timetable_url(@timetable)
  end

  test 'should get edit' do
    log_in_as(@admin)
    get edit_admin_table_time_url(@table_time)

    assert_response :success
  end

  test 'should update table_time' do
    log_in_as(@admin)
    patch admin_table_time_url(@table_time), params: { table_time: { start: @table_time.start } }
    assert_redirected_to admin_timetable_path(@timetable)
  end

  test 'should destroy table_time' do
    log_in_as(@admin)
    assert_difference('TableTime.count', -1) do
      delete admin_table_time_url(@table_time)
    end

    assert_redirected_to admin_timetable_path(@timetable)
  end
end
