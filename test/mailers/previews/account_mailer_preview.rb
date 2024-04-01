# Preview all emails at http://localhost:3000/rails/mailers/account_mailer
class AccountMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/account_mailer/password_reset
  def password_reset
    account = Account.find_by(email: 'james@test.com')
    account.reset_token = Account.new_token
    AccountMailer.password_reset(account)
  end
end
