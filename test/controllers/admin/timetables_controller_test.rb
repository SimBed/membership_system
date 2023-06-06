require 'test_helper'

class Admin::TimetablesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @timetable = timetables(:publictim)
    @admin = accounts(:admin)
  end

  test 'should get index' do
    log_in_as(@admin)
    get admin_timetables_url

    assert_response :success
  end

  test 'should get new' do
    log_in_as(@admin)
    get new_admin_timetable_url

    assert_response :success
  end

  test 'should create timetable' do
    log_in_as(@admin)
    assert_difference('Timetable.count') do
      post admin_timetables_url, params: { timetable: { title: @timetable.title } }
    end

    assert_redirected_to admin_timetable_url(Timetable.last)
  end

  test 'should show timetable' do
    log_in_as(@admin)
    get admin_timetable_url(@timetable)

    assert_response :success
  end

  test 'should get edit' do
    log_in_as(@admin)
    get edit_admin_timetable_url(@timetable)

    assert_response :success
  end

  test 'should update timetable' do
    log_in_as(@admin)
    patch admin_timetable_url(@timetable), params: { timetable: { title: @timetable.title } }

    assert_redirected_to admin_timetable_url(@timetable)
  end

  test 'should destroy timetable' do
    log_in_as(@admin)
    assert_difference('Timetable.count', -1) do
      delete admin_timetable_url(@timetable)
    end

    assert_redirected_to admin_timetables_url
  end
end
