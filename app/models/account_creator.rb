class AccountCreator
  include PasswordWizard
  # Style Guide discourages the simpler OpenStruct
  # set Struct to constant in class not in method. COnstants can't be set in methods 'dynamic-constant-assignment error' 
  Outcome = Struct.new(:success?, :password, :account)
  
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
      #   OpenStruct.new(success?: true, password: @password, account:)
      Outcome.new(true, @password, account)
    else
      #   OpenStruct.new(success?: false, account:)
      Outcome.new(false, nil, account)
    end
  end
end
