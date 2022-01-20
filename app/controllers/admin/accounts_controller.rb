class Admin::AccountsController < Admin::BaseController
  def create
    @account = Account.new(account_params)

      if @account.save
        redirect_to admin_clients_path
        flash[:success] = "account was successfully created"
      else
        redirect_to admin_clients_path
        flash[:warning] = "account was not created"
      end
  end

  def destroy
  end

  private
    def account_params
      password_params = {password: 'password', password_confirmation: 'password'}
      activation_params = {activated: true}
      params.permit(:email).merge(password_params).merge(activation_params)
    end
end
