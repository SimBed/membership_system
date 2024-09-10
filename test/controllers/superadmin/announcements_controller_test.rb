require "test_helper"

class Superadmin::AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @announcement = announcements(:one)
  end

  test 'should redirect new when not logged in as superadmin' do
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get new_announcement_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect show when not logged in as superadmin' do
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get announcement_path(@announcement)

      assert_redirected_to login_path
    end
  end  

  test 'should redirect index when not logged in as superadmin' do
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get announcements_path

      assert_redirected_to login_path
    end
  end  

  test 'should redirect create when not logged in as superadmin' do
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Announcement.count' do
        post announcements_path, params:
         { announcement:
            { message: 'no parking on the road'} }
      end
    end
  end

  test 'should redirect edit when not logged in as superadmin' do
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get edit_announcement_path(@announcement)

      assert_redirected_to login_path
    end
  end

  test 'should redirect update when not logged in as superadmin' do
    original_message = @announcement.message
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      patch announcement_path(@announcement), params:
       { announcement:
          { message: 'you can park on the road' } }

      assert_equal original_message, @announcement.reload.message
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as superadmin' do
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Announcement.count' do
        delete announcement_path(@announcement)
      end
    end
  end  

end
