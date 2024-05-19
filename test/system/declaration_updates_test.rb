require "application_system_test_case"

class DeclarationUpdatesTest < ApplicationSystemTestCase
  setup do
    @declaration_update = declaration_updates(:one)
  end

  test "visiting the index" do
    visit declaration_updates_url
    assert_selector "h1", text: "Declaration updates"
  end

  test "should create declaration update" do
    visit declaration_updates_url
    click_on "New declaration update"

    fill_in "Date", with: @declaration_update.date
    fill_in "Declaration", with: @declaration_update.declaration_id
    fill_in "Note", with: @declaration_update.note
    click_on "Create Declaration update"

    assert_text "Declaration update was successfully created"
    click_on "Back"
  end

  test "should update Declaration update" do
    visit declaration_update_url(@declaration_update)
    click_on "Edit this declaration update", match: :first

    fill_in "Date", with: @declaration_update.date
    fill_in "Declaration", with: @declaration_update.declaration_id
    fill_in "Note", with: @declaration_update.note
    click_on "Update Declaration update"

    assert_text "Declaration update was successfully updated"
    click_on "Back"
  end

  test "should destroy Declaration update" do
    visit declaration_update_url(@declaration_update)
    click_on "Destroy this declaration update", match: :first

    assert_text "Declaration update was successfully destroyed"
  end
end
