require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
  end

  # new, create, destroy methods only for sessions controller
  # requests to destroy are not sent with parameters, so no test for invalid requests
  # (valid requests are tested in integration tests)

  test 'should get new' do
    get login_path
    assert_response :success
  end

  test 'admin invalid login' do
    [@junioradmin, @admin, @superadmin].each do |account_holder|
      post login_path, params: { session: { email: account_holder.email, password: '' } }
      # assert_template 'sessions/new' - deprecated
      refute_predicate flash, :empty?
    end
  end

  test 'client invalid login' do
    post login_path, params: { session: { email: @account_client1.email, password: '' } }
    refute_predicate flash, :empty?
  end

  test 'partner invalid login' do
    post login_path, params: { session: { email: @account_partner1.email, password: '' } }
    refute_predicate flash, :empty?
  end
end
