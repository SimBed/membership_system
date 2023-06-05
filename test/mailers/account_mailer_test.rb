require "test_helper"

class AccountMailerTest < ActionMailer::TestCase
  test "password_reset" do
    account = accounts(:client1)
    account.reset_token = Account.new_token    
    mail = AccountMailer.password_reset(account)
    assert_equal 'Password reset', mail.subject
    assert_equal [account.email], mail.to
    assert_equal ['dan@thespacejuhu.in'], mail.from
    assert_match account.reset_token, mail.body.encoded
    assert_match CGI.escape(account.email), mail.body.encoded
  end
end
