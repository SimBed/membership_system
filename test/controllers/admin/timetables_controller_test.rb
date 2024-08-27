require 'test_helper'

class Admin::TimetablesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @timetable = timetables(:mar22)
    @admin = accounts(:admin)
  end

  test 'should get index' do
    log_in_as(@admin)
    get timetables_path

    assert_response :success
  end

  test 'should get new' do
    log_in_as(@admin)
    get new_timetable_path

    assert_response :success
  end

  test 'should create timetable' do
    log_in_as(@admin)
    assert_difference('Timetable.count') do
      post timetables_path, params: { timetable: { title: 'July22',
                                                   date_from: '2022-01-07' ,
                                                   date_until: '2022-31-07'  } }
    end

    assert_redirected_to timetable_path(Timetable.last)
  end

  test 'should show timetable' do
    log_in_as(@admin)
    get timetable_path(@timetable)

    assert_response :success
  end

  test 'should get edit' do
    log_in_as(@admin)
    get edit_timetable_path(@timetable)

    assert_response :success
  end

  test 'should update timetable' do
    log_in_as(@admin)
    patch timetable_path(@timetable), params: { timetable: { title: 'Aug22' } }

    assert_redirected_to timetables_path
  end

  test 'should destroy timetable' do
    log_in_as(@admin)
    assert_difference('Timetable.count', -1) do
      delete timetable_path(@timetable)
    end

    assert_redirected_to timetables_path
  end
end
