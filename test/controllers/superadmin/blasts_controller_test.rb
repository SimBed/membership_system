require "test_helper"

class Superadmin::BlastsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get blast_path
    assert_response :redirect
  end
end