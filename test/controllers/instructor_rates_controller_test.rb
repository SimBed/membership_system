require "test_helper"

class InstructorRatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @instructor_rate = instructor_rates(:one)
  end

  test "should get index" do
    get instructor_rates_url
    assert_response :success
  end

  test "should get new" do
    get new_instructor_rate_url
    assert_response :success
  end

  test "should create instructor_rate" do
    assert_difference('InstructorRate.count') do
      post instructor_rates_url, params: { instructor_rate: { date_from: @instructor_rate.date_from, instructor_id: @instructor_rate.instructor_id, rate: @instructor_rate.rate } }
    end

    assert_redirected_to instructor_rate_url(InstructorRate.last)
  end

  test "should show instructor_rate" do
    get instructor_rate_url(@instructor_rate)
    assert_response :success
  end

  test "should get edit" do
    get edit_instructor_rate_url(@instructor_rate)
    assert_response :success
  end

  test "should update instructor_rate" do
    patch instructor_rate_url(@instructor_rate), params: { instructor_rate: { date_from: @instructor_rate.date_from, instructor_id: @instructor_rate.instructor_id, rate: @instructor_rate.rate } }
    assert_redirected_to instructor_rate_url(@instructor_rate)
  end

  test "should destroy instructor_rate" do
    assert_difference('InstructorRate.count', -1) do
      delete instructor_rate_url(@instructor_rate)
    end

    assert_redirected_to instructor_rates_url
  end
end
