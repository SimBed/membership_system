require "test_helper"

class Shared::DeclarationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @instructor_account = accounts(:head_coach)
    @client = clients(:client_ekta_unlimited)
    @client1 = @account_client1.client
  end

  test 'should redirect new when not logged in as correct client' do
    [nil, @instructor, @superadmin, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      get new_client_declaration_path(@client1)

      assert_redirected_to login_path
    end
  end  

  test 'should redirect update when not logged in as correct client' do
    [nil, @instructor_account, @superadmin, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      patch client_declaration_path(@client1), params:
        { client:
          { dob: "1980-01-01",
            gender: 'female',           
            declaration_attributes: {
              terms_and_conditions: true,
              payment_policy: true,
              privacy_policy: true,
              indemnity: true
          } } }

      assert_redirected_to login_path
    end
  end  

  test 'should redirect index when not logged in as admin or instructor' do
    [nil, @account_client1].each do |account_holder|
      log_in_as(account_holder)
      get declarations_path

      assert_redirected_to login_path
    end
  end  

  test 'should redirect show when not logged in as admin or instructor or correct client' do
    [nil, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      get client_declaration_path(@client1)

      assert_redirected_to login_path
    end
  end  
end
