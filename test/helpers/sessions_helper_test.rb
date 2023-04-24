require 'test_helper'
class SessionsHelperTest < ActionView::TestCase
  def setup
    @admin = accounts(:admin)
    remember(@admin)
  end

  test 'current_account remembers and returns right account when session is nil' do
    assert current_account?(@admin)
    assert logged_in_as?('admin')
  end

  test 'current_account returns nil when remember digest is wrong' do
    @admin.update_column(:remember_digest, Account.digest(Account.new_token))
    assert_nil current_account
    assert_nil current_role
  end

end
