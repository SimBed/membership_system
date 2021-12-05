require "application_system_test_case"

class PurchasesTest < ApplicationSystemTestCase
  setup do
    @purchase = purchases(:one)
  end

  test "visiting the index" do
    visit purchases_url
    assert_selector "h1", text: "Purchases"
  end

  test "creating a Purchase" do
    visit purchases_url
    click_on "New Purchase"

    check "Adjust restart" if @purchase.adjust_restart
    fill_in "Ar date", with: @purchase.ar_date
    fill_in "Ar payment", with: @purchase.ar_payment
    fill_in "Client", with: @purchase.client_id
    fill_in "Dop", with: @purchase.dop
    fill_in "Invoice", with: @purchase.invoice
    fill_in "Note", with: @purchase.note
    fill_in "Payment", with: @purchase.payment
    fill_in "Payment mode", with: @purchase.payment_mode
    fill_in "Product", with: @purchase.product_id
    click_on "Create Purchase"

    assert_text "Purchase was successfully created"
    click_on "Back"
  end

  test "updating a Purchase" do
    visit purchases_url
    click_on "Edit", match: :first

    check "Adjust restart" if @purchase.adjust_restart
    fill_in "Ar date", with: @purchase.ar_date
    fill_in "Ar payment", with: @purchase.ar_payment
    fill_in "Client", with: @purchase.client_id
    fill_in "Dop", with: @purchase.dop
    fill_in "Invoice", with: @purchase.invoice
    fill_in "Note", with: @purchase.note
    fill_in "Payment", with: @purchase.payment
    fill_in "Payment mode", with: @purchase.payment_mode
    fill_in "Product", with: @purchase.product_id
    click_on "Update Purchase"

    assert_text "Purchase was successfully updated"
    click_on "Back"
  end

  test "destroying a Purchase" do
    visit purchases_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Purchase was successfully destroyed"
  end
end
