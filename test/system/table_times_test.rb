require 'application_system_test_case'

class TableTimesTest < ApplicationSystemTestCase
  setup do
    @table_time = table_times(:one)
  end

  test 'visiting the index' do
    visit table_times_url

    assert_selector 'h1', text: 'Table Times'
  end

  test 'creating a Table time' do
    visit table_times_url
    click_on 'New Table Time'

    fill_in 'Start', with: @table_time.start
    click_on 'Create Table time'

    assert_text 'Table time was successfully created'
    click_on 'Back'
  end

  test 'updating a Table time' do
    visit table_times_url
    click_on 'Edit', match: :first

    fill_in 'Start', with: @table_time.start
    click_on 'Update Table time'

    assert_text 'Table time was successfully updated'
    click_on 'Back'
  end

  test 'destroying a Table time' do
    visit table_times_url
    page.accept_confirm do
      click_on 'Destroy', match: :first
    end

    assert_text 'Table time was successfully destroyed'
  end
end
