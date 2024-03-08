require "test_helper"

class Superadmin::BlastsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get superadmin_blasts_new_url
    assert_response :redirect
  end
end
