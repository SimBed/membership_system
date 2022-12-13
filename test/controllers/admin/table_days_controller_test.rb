require "test_helper"

class Admin::TableDaysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @table_day = table_days(:one)
    @timetable = timetables(:publictim)
    @admin = accounts(:admin)
  end

  test "should get new" do
    log_in_as(@admin)
    get new_admin_table_day_url
    assert_response :success
  end

  test "should create table_day" do
    log_in_as(@admin)
    assert_difference('TableDay.count') do
      post admin_table_days_url, params: {
                                   table_day: {
                                     name: @table_day.name,
                                     short_name: @table_day.short_name,
                                     timetable_id: @timetable.id } }
    end

    assert_redirected_to admin_timetable_url(@timetable)
  end

  test "should get edit" do
    log_in_as(@admin)
    get edit_admin_table_day_url(@table_day)
    assert_response :success
  end

  test "should update table_day" do
    log_in_as(@admin)
    patch admin_table_day_url(@table_day), params: { table_day: { name: @table_day.name, short_name: @table_day.short_name } }
    assert_redirected_to admin_timetable_url(@timetable)
  end

  test "should destroy table_day" do
    log_in_as(@admin)
    assert_difference('TableDay.count', -1) do
      delete admin_table_day_url(@table_day)
    end

    assert_redirected_to admin_timetable_url(@timetable)
  end
end
