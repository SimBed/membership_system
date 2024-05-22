require 'test_helper'

class InstructorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @instructor = instructors(:amit)
  end

  # no show method for instructors controller

  test 'should redirect new when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get new_instructor_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get instructors_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get edit_instructor_path(@instructor)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Instructor.count' do
        post instructors_path, params:
         { instructor:
            { first_name: 'Newcoach',
              last_name: 'Biglifter' } }
      end
    end
  end

  test 'should redirect update when not logged in as admin or more senior' do
    original_last_name = @instructor.last_name
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      patch instructor_path(@instructor), params:
       { instructor:
          { first_name: @instructor.first_name,
            last_name: 'Newname' } }

      assert_equal original_last_name, @instructor.reload.last_name
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Instructor.count' do
        delete instructor_path(@instructor)
      end
    end
  end
end
