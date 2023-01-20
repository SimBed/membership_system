require "test_helper"

class FooterControllerTest < ActionDispatch::IntegrationTest
  test "should get about" do
    get about_url
    assert_response :success
  end

  test "should get terms" do
    get '/terms&conditions'
    assert_response :success
  end

  test "should get charges" do
    get '/charges&deductions'
    assert_response :success
  end

  test "should get privacy policy" do
    get privacy_policy_path
    assert_response :success
  end

  test "should get payment policy" do
    get payment_policy_path
    assert_response :success
  end
end
