require "test_helper"

class AccountTest < ActiveSupport::TestCase
  def setup
    @account = Account.new(email: "user@example.com", password: "foobar", password_confirmation: "foobar")
  end

  test "should be valid" do
    assert @account.valid?
  end
end
