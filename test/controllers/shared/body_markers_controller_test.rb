require "test_helper"

class Shared::BodyMarkersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @client = clients(:client_ekta_unlimited)
    @client1 = @account_client1.client
    @bodymarker_for_client1 = body_markers(:one)
  end

  test 'should redirect new when not logged in as admin or more senior, instructor or client' do
    [nil, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get new_body_marker_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as admin or more senior, instructor or client' do
    [nil, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get body_markers_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as admin or more senior, instructor or correct client' do
    [nil, @junioradmin, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      get edit_body_marker_path(@bodymarker_for_client1)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as admin or more senior, instructor or correct client' do
    [nil, @junioradmin, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'BodyMarker.count' do
        post body_markers_path, params:
          { body_marker:
             { bodypart: 'Neck',
               measurement: 22,
               date: '2024-01-15',
               client_id: @client1.id} }
      end
    end
  end

  test 'should redirect update when not logged in as admin or more senior, instructor or correct client' do
    original_measurement = @bodymarker_for_client1.measurement
    [nil, @junioradmin, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      patch body_marker_path(@bodymarker_for_client1), params:
        { body_marker:
           { measurement: original_measurement + 5 } }

      assert_equal original_measurement, @bodymarker_for_client1.reload.measurement
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged as admin or more senior, instructor or correct client' do
    [nil, @junioradmin, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'BodyMarker.count' do
        delete body_marker_path(@bodymarker_for_client1)
      end
    end
  end
end
