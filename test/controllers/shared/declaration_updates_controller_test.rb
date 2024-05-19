require "test_helper"

class DeclarationUpdatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superadmin = accounts(:superadmin)
    @admin = accounts(:admin)
    @junioradmin = accounts(:junioradmin)
    @instructor_account = accounts(:no_admin_instructor)
    @account_client1 = accounts(:client1)
    @client1 = @account_client1.client
    @declaration = declarations(:one)
    @declaration_update = declaration_updates(:one)
  end
  
  test 'should redirect new when not logged in as junioradmin or more senior' do
    [nil, @instructor_account, @account_client1].each do |account_holder|
      log_in_as(account_holder)
      get new_client_declaration_declaration_update_path(client_id: @client1)
      
      assert_redirected_to login_path
    end
  end  
  
  test 'should redirect create when not logged in as junioradmin or more senior' do
    [nil, @instructor_account, @account_client1].each do |account_holder|
      log_in_as(account_holder)
      post client_declaration_declaration_updates_path(client_id: @client1.id),
            params: { declaration_update:
            { date: Date.parse('17 May 2024'),
              note: 'some info, more info',
              declaration_id: @declaration.id  } }
  
      assert_redirected_to login_path
    end
  end
  
  test 'should redirect edit when not logged in as junioradmin or more senior' do
    [nil, @instructor_account, @account_client1].each do |account_holder|
      log_in_as(account_holder)
      get edit_client_declaration_declaration_update_path(client_id: @client1.id, id: @declaration_update.id)
      
      assert_redirected_to login_path
    end
  end  


  test 'should redirect update when not logged in as junioradmin or more senior' do
    [nil, @instructor_account, @account_client1].each do |account_holder|
      log_in_as(account_holder)
      patch client_declaration_declaration_update_path(client_id: @client1.id, id: @declaration_update.id),
            params: { declaration_update:
                      { note: 'some info, more info' } }
      assert_redirected_to login_path
    end
  end

  test 'should redirect show when not logged in as instructor, junioradmin or more senior' do
    [nil, @account_client1].each do |account_holder|
      log_in_as(account_holder)
      get client_declaration_declaration_update_path(client_id: @client1.id, id: @declaration_update.id)

      assert_redirected_to login_path
    end
  end    

  test 'should redirect destroy when not logged in as admin or more senior' do
    [nil, @instructor_account, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      delete client_declaration_declaration_update_path(client_id: @client1.id, id: @declaration_update.id)

      assert_redirected_to login_path
    end
  end    


  # test "should get new" do
  #   get new_declaration_update_url
  #   assert_response :success
  # end

  # test "should create declaration_update" do
  #   assert_difference("DeclarationUpdate.count") do
  #     post declaration_updates_url, params: { declaration_update: { date: @declaration_update.date, declaration_id: @declaration_update.declaration_id, note: @declaration_update.note } }
  #   end

  #   assert_redirected_to declaration_update_url(DeclarationUpdate.last)
  # end

  # test "should show declaration_update" do
  #   get declaration_update_url(@declaration_update)
  #   assert_response :success
  # end

  # test "should get edit" do
  #   get edit_declaration_update_url(@declaration_update)
  #   assert_response :success
  # end

  # test "should update declaration_update" do
  #   patch declaration_update_url(@declaration_update), params: { declaration_update: { date: @declaration_update.date, declaration_id: @declaration_update.declaration_id, note: @declaration_update.note } }
  #   assert_redirected_to declaration_update_url(@declaration_update)
  # end

  # test "should destroy declaration_update" do
  #   assert_difference("DeclarationUpdate.count", -1) do
  #     delete declaration_update_url(@declaration_update)
  #   end

  #   assert_redirected_to declaration_updates_url
  # end
end
