require "test_helper"

class WkclassesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @wkclass = wkclasses(:one)
  end

  test "should get index" do
    get wkclasses_url
    assert_response :success
  end

  test "should get new" do
    get new_wkclass_url
    assert_response :success
  end

  test "should create wkclass" do
    assert_difference('Wkclass.count') do
      post wkclasses_url, params: { wkclass: { start_time: @wkclass.start_time, workout_id: @wkclass.workout_id } }
    end

    assert_redirected_to wkclass_url(Wkclass.last)
  end

  test "should show wkclass" do
    get wkclass_url(@wkclass)
    assert_response :success
  end

  test "should get edit" do
    get edit_wkclass_url(@wkclass)
    assert_response :success
  end

  test "should update wkclass" do
    patch wkclass_url(@wkclass), params: { wkclass: { start_time: @wkclass.start_time, workout_id: @wkclass.workout_id } }
    assert_redirected_to wkclass_url(@wkclass)
  end

  test "should destroy wkclass" do
    assert_difference('Wkclass.count', -1) do
      delete wkclass_url(@wkclass)
    end

    assert_redirected_to wkclasses_url
  end
end
