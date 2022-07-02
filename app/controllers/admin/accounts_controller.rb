class Admin::AccountsController < Admin::BaseController
  before_action :correct_credentials
  before_action :set_account_holder
  # accounts can't be updated/destroyed through the app
  # admin accounts cant be created through the app

  def create
    @password = Account.password_wizard(6)
    @account = Account.new(account_params)
    if @account.save
      associate_account_holder_to_account
      flash_message :success, t('.success')
      flash_message *Whatsapp.new(whatsapp_params).manage_messaging
    else
      flash_message :warning, t('.warning')
    end
    redirect_back fallback_location: admin_clients_path
  end

  private

  def correct_credentials
    only_client_or_partner_accounts_can_be_made_here
    only_superadmin_makes_partner_accounts
  end

  def only_client_or_partner_accounts_can_be_made_here
    # administrator accounts cannot be created through the app
    return if %w[client partner].include?(params[:ac_type])

    flash[:warning] = t('.warning')
    redirect_to(login_path) && return
  end

  def only_superadmin_makes_partner_accounts
    # admin can create client's account, but only superadmin can create partner's account
    return unless params[:ac_type] == 'partner' && !logged_in_as?('superadmin')

    flash[:warning] = t('.warning')
    redirect_to login_path
  end

  def set_account_holder
    # don't create account if for some reason there is no associated account holder
    # used 'where' rather than 'find' as find returns an error (rather than nil or empty object) when record not found
    @account_holder = Client.where(id: params[:client_id]).first if params[:ac_type] == 'client'
    @account_holder = Partner.where(id: params[:partner_id]).first if params[:ac_type] == 'partner'
    (redirect_to(login_path) && return) if @account_holder.nil?
  end

  def associate_account_holder_to_account
    @account_holder.update(account_id: @account.id)
  end

  def account_params
    password_params = { password: @password, password_confirmation: @password }
    activation_params = { activated: true, ac_type: params[:ac_type] }
    params.permit(:email, :ac_type).merge(password_params).merge(activation_params)
  end

  def whatsapp_params
    { receiver: @account_holder,
      message_type: 'new_account',
      variable_contents: { password: @password }  }
  end
end
