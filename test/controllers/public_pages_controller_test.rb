require "test_helper"

class PublicPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get welcome" do
    get public_pages_welcome_url
    assert_response :success
  end
end
