require 'test_helper'

class PublicPagesControllerTest < ActionDispatch::IntegrationTest
  # public pages controller just has a welcome method
  # the redirection based on login is done in the view. This should be reformatted, so it is done in the controller and can be tested
  test 'should get welcome' do
    get public_pages_welcome_path
    assert_response :success
  end

  # test 'should get clients index if junior admin or more senior' do
  #   [@junioradmin, @admin, @superadmin].each do |account_holder|
  #     log_in_as(account_holder)
  #     get public_pages_welcome_path
  #     assert_redirected_to admin_clients_path
  #   end
  # end
end
