require 'application_system_test_case'

class TableDaysTest < ApplicationSystemTestCase
  setup do
    @table_day = table_days(:one)
  end

  test 'visiting the index' do
    visit table_days_url

    assert_selector 'h1', text: 'Table Days'
  end

  test 'creating a Table day' do
    visit table_days_url
    click_on 'New Table Day'

    fill_in 'Name', with: @table_day.name
    fill_in 'Short name', with: @table_day.short_name
    click_on 'Create Table day'

    assert_text 'Table day was successfully created'
    click_on 'Back'
  end

  test 'updating a Table day' do
    visit table_days_url
    click_on 'Edit', match: :first

    fill_in 'Name', with: @table_day.name
    fill_in 'Short name', with: @table_day.short_name
    click_on 'Update Table day'

    assert_text 'Table day was successfully updated'
    click_on 'Back'
  end

  test 'destroying a Table day' do
    visit table_days_url
    page.accept_confirm do
      click_on 'Destroy', match: :first
    end

    assert_text 'Table day was successfully destroyed'
  end
end
