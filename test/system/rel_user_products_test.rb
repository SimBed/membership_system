require "application_system_test_case"

class RelUserProductsTest < ApplicationSystemTestCase
  setup do
    @rel_user_product = rel_user_products(:one)
  end

  test "visiting the index" do
    visit rel_user_products_url
    assert_selector "h1", text: "Rel User Products"
  end

  test "creating a Rel user product" do
    visit rel_user_products_url
    click_on "New Rel User Product"

    fill_in "Dop", with: @rel_user_product.dop
    fill_in "Payment", with: @rel_user_product.payment
    fill_in "Product", with: @rel_user_product.product_id
    fill_in "User", with: @rel_user_product.user_id
    click_on "Create Rel user product"

    assert_text "Rel user product was successfully created"
    click_on "Back"
  end

  test "updating a Rel user product" do
    visit rel_user_products_url
    click_on "Edit", match: :first

    fill_in "Dop", with: @rel_user_product.dop
    fill_in "Payment", with: @rel_user_product.payment
    fill_in "Product", with: @rel_user_product.product_id
    fill_in "User", with: @rel_user_product.user_id
    click_on "Update Rel user product"

    assert_text "Rel user product was successfully updated"
    click_on "Back"
  end

  test "destroying a Rel user product" do
    visit rel_user_products_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Rel user product was successfully destroyed"
  end
end
