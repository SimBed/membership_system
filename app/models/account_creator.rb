class AccountCreator
  include PasswordWizard
  def initialize(attributes = {})
    @email = attributes[:email]
    @ac_type = attributes[:ac_type]
    @account_holder = attributes[:account_holder]
    @password = AccountCreator.password_wizard(Setting.password_length)
  end

  def create
    account_params = { email: @email,
                       ac_type: @ac_type,
                       activated: true,
                       password: @password,
                       password_confirmation: @password }
    account = Account.new(account_params)
    if account.save
      Assignment.create(account_id: account.id, role_id: Role.find_by(name: @ac_type).id)
      @account_holder.update(account_id: account.id)
      OpenStruct.new(success?: true, password: @password, account:)
    else
      OpenStruct.new(success?: false, account:)
    end
  end
end
