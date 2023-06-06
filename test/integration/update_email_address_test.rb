require 'test_helper'

class UpdateEmailAddressTest < ActionDispatch::IntegrationTest
  def setup
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.client
    @admin = accounts(:admin)
  end

  test 'test account email updates when client email edited' do
    log_in_as(@admin)
    new_email = @client.email.gsub('@', '2@')
    patch admin_client_path(@client), params: { client: { email: new_email } }

    assert_equal new_email, @account_client.reload.email
  end
end
