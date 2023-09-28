require "application_system_test_case"

class OtherServicesTest < ApplicationSystemTestCase
  setup do
    @other_service = other_services(:one)
  end

  test "visiting the index" do
    visit other_services_url
    assert_selector "h1", text: "Other services"
  end

  test "should create other service" do
    visit other_services_url
    click_on "New other service"

    fill_in "Link", with: @other_service.link
    fill_in "Name", with: @other_service.name
    click_on "Create Other service"

    assert_text "Other service was successfully created"
    click_on "Back"
  end

  test "should update Other service" do
    visit other_service_url(@other_service)
    click_on "Edit this other service", match: :first

    fill_in "Link", with: @other_service.link
    fill_in "Name", with: @other_service.name
    click_on "Update Other service"

    assert_text "Other service was successfully updated"
    click_on "Back"
  end

  test "should destroy Other service" do
    visit other_service_url(@other_service)
    click_on "Destroy this other service", match: :first

    assert_text "Other service was successfully destroyed"
  end
end
