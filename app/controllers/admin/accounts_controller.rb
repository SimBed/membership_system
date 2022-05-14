class Admin::AccountsController < Admin::BaseController
  before_action :correct_credentials
  before_action :set_account_holder
  # accounts can't be updated/destroyed through the app
  # admin accounts cant be created through the app

  def create
    @account = Account.new(account_params)
    if @account.save
      associate_account_holder_to_account
      flash[:success] = 'account was successfully created'
    else
      flash[:warning] = 'account was not created'
    end
    redirect_back fallback_location: admin_clients_path
  end

  private

  def correct_credentials
    # administrator accounts cannot be created through the app
    unless %w[client partner].include?(params[:ac_type])
      flash[:warning] = 'Forbidden'
      redirect_to(login_path) and return
    end
    # admin can create client's account, but only superadmin can create partner's account
    if params[:ac_type] == 'partner' && !logged_in_as?('superadmin')
      flash[:warning] = 'Forbidden'
      redirect_to(login_path) and return
    end
  end

  def set_account_holder
    # don't create account if for some reason there is no associated account holder
    # used 'where' rather than 'find' as find returns an error (rather than nil or empty object) when record not found
    @account_holder = Client.where(id: params[:client_id]) if params[:ac_type] == 'client'
    @account_holder = Partner.where(id: params[:partner_id]) if params[:ac_type] == 'partner'
    (redirect_to(login_path) and return) if @account_holder.empty?
  end

  def associate_account_holder_to_account
    @account_holder.update(account_id: @account.id)
  end

  def account_params
    password_params = { password: 'password', password_confirmation: 'password' }
    activation_params = { activated: true, ac_type: params[:ac_type] }
    params.permit(:email, :ac_type).merge(password_params).merge(activation_params)
  end
end
