require 'test_helper'

class Admin::TableDaysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @table_day = table_days(:mon1)
    @timetable = timetables(:mar22)
    @admin = accounts(:admin)
  end

  test 'should get new' do
    log_in_as(@admin)
    get new_table_day_path

    assert_response :success
  end

  test 'should create table_day' do
    log_in_as(@admin)
    assert_difference('TableDay.count') do
      post table_days_path, params: {
        table_day: {
          name: 'Extraday',
          short_name: 'ext',
          timetable_id: @timetable.id
        }
      }
    end

    assert_redirected_to timetable_path(@timetable)
  end

  test 'should get edit' do
    log_in_as(@admin)
    get edit_table_day_path(@table_day)

    assert_response :success
  end

  test 'should update table_day' do
    log_in_as(@admin)
    patch table_day_path(@table_day), params: { table_day: { name: @table_day.name + '5', short_name: @table_day.short_name } }

    assert_redirected_to timetable_path(@timetable)
  end

  test 'should destroy table_day' do
    log_in_as(@admin)
    assert_difference('TableDay.count', -1) do
      delete table_day_path(@table_day)
    end

    assert_redirected_to timetable_path(@timetable)
  end
end