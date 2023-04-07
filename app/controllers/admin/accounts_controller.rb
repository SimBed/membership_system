class Admin::AccountsController < Admin::BaseController
  before_action :correct_credentials, only: [:create]
  before_action :set_account_holder, only: [:create]
  before_action :set_account, only: [:update]
  skip_before_action :admin_account,  only: [:index, :update]
  before_action :correct_account_or_junioradmin, only: [:update]
  before_action :superadmin_account, only: [:index]
  # accounts can't be updated/destroyed through the app
  # admin accounts cant be created through the app
  
  def index
    @accounts = Account.where(ac_type: ['junioradmin', 'admin', 'superadmin']).order_by_ac_type
    render 'superadmin/accounts/index.html'
  end

  def create
    @password = Account.password_wizard(Setting.password_length)
    @account = Account.new(account_params)
    if @account.save
      associate_account_holder_to_account
      flash_message :success, t('.success')
      flash_message(*Whatsapp.new(whatsapp_params('new_account')).manage_messaging)
    else
      flash_message :warning, t('.warning')
    end
    redirect_back fallback_location: admin_clients_path
  end

  def update
    if params[:account].nil? # means request came from admin link
      password_reset_admin_of_client
    elsif params[:account][:requested_by] == 'superadmin_of_admin'
      password_reset_superadmin_of_admin
    else
      password_reset_client_of_client
    end
  end
  
  private
  
  def password_reset_admin_of_client
    @password = Account.password_wizard(Setting.password_length)
    @account.update(password: @password, password_confirmation: @password)
    flash_message(*Whatsapp.new(whatsapp_params('password_reset')).manage_messaging)
    redirect_back fallback_location: admin_clients_path
  end
  
  def password_reset_superadmin_of_admin
    passwords_the_same = (password_update_params[:new_password] == password_update_params[:new_password_confirmation])
    @account.errors.add(:base, "passwords not the same") unless passwords_the_same
    if passwords_the_same && @account.update(password: password_update_params[:new_password], password_confirmation: password_update_params[:new_password]) 
      flash_message :success, t('.success')
    else
      flash[:warning] = "Update failed. Passwords either don't match or too short (min 6 characters)"
     end
     redirect_to admin_accounts_path
  end

  def password_reset_client_of_client
    passwords_the_same = (password_update_params[:new_password] == password_update_params[:new_password_confirmation])
    @account.errors.add(:base, "passwords not the same") unless passwords_the_same
    if passwords_the_same && @account.update(password: password_update_params[:new_password], password_confirmation: password_update_params[:new_password]) 
      flash_message :success, t('.success')
      redirect_back fallback_location: login_path
    else
      # reformat - this code is reused in show method of clients controller
      @client = @account.clients.first
      @client_hash = {
        attendances: @client.attendances.attended.size,
        last_class: @client.last_class,
        date_created: @client.created_at,
        date_last_purchase_expiry: @client.last_purchase&.expiry_date
      }
      render 'client/clients/show', layout: 'client'
     end  
  end


  def correct_account_or_junioradmin
    return if current_account?(@account) || logged_in_as?('junioradmin', 'admin', 'superadmin')

    flash_message :warning, t('.warning')
    redirect_to login_path
  end

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

  def set_account
    @account = Account.find(params[:id])
    @account_holder = @account.clients.first
  end

  def associate_account_holder_to_account
    # return to #update when sorted out whatsapp validation. New account failure if whatsapp nil (alternatively set modifier_is_client to false)
    @account_holder.update(account_id: @account.id)
    # @account_holder.update_column(:account_id, @account.id)
  end

  def account_params
    password_params = { password: @password, password_confirmation: @password }
    activation_params = { activated: true, ac_type: params[:ac_type] }
    params.permit(:email, :ac_type).merge(password_params).merge(activation_params)
  end

  def password_update_params
    params.require(:account).permit(:new_password, :new_password_confirmation, :requested_by)
  end  

  def whatsapp_params(message_type)
    { receiver: @account_holder,
      message_type: message_type,
      variable_contents: { first_name: @account_holder.first_name, password: @password } }      
  end
end
