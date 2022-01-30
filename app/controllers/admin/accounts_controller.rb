class Admin::AccountsController < Admin::BaseController
before_action :set_account_holder

  def create
    @account = Account.new(account_params)
      if @account.save
        associate_account_holder_to_account
        flash[:success] = "account was successfully created"
      else
        flash[:warning] = "account was not created"
      end
      redirect_back fallback_location: admin_clients_path
  end

  def destroy
  end

  private
    def associate_account_holder_to_account
      @account_holder.update(account_id: @account.id)
    end

    def account_params
      password_params = {password: 'password', password_confirmation: 'password'}
      activation_params = {activated: true, ac_type: params[:ac_type]}
      params.permit(:email, :ac_type).merge(password_params).merge(activation_params)
    end

    def set_account_holder
      @account_holder = Client.find(params[:client_id]) if params[:ac_type] == 'client'
      @account_holder = Partner.find(params[:partner_id]) if params[:ac_type] == 'partner'
    end

end
