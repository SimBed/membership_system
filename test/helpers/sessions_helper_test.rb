require 'test_helper'
class SessionsHelperTest < ActionView::TestCase
  def setup
    @account = accounts(:admin)
    remember(@account)
  end

  test 'current_user remembers and returns right user when session is nil' do
    assert current_account?(@account)
    assert logged_in_as?('admin')
  end

  test 'current_user returns nil when remember digest is wrong' do
    @account.update_column(:remember_digest, Account.digest(Account.new_token))
    assert_nil current_account
  end
end
