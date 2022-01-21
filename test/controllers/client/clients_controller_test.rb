require "test_helper"

class Client::ClientsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get client_clients_show_url
    assert_response :success
  end
end
