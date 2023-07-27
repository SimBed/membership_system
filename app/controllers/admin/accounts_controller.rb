class Admin::AccountsController < Admin::BaseController
  before_action :correct_credentials, only: [:create]
  before_action :set_account_holder, only: [:create]
  before_action :set_account, only: [:update]
  skip_before_action :admin_account, only: [:index, :update]
  before_action :correct_account_or_junioradmin, only: [:update]
  before_action :superadmin_account, only: [:index]
  # accounts can't be updated/destroyed through the app
  # admin accounts cant be created through the app

  def index
    @accounts = Account.where(ac_type: %w[junioradmin admin superadmin]).order_by_ac_type
    render 'superadmin/accounts/index.html'
  end

  def create
    result = AccountCreator.new(account_params).create
    if result.success?
      flash_message :success, t('.success')
      message_type = params[:ac_type] == 'instructor' ? 'new_instructor_account' : 'new_account'
      flash_message(*Whatsapp.new(whatsapp_params(message_type, result.password)).manage_messaging)
    else
      flash_message :warning, t('.warning')
    end
    redirect_back fallback_location: admin_clients_path    
    # @password = Account.password_wizard(Setting.password_length)
    # @account = Account.new(account_params)
    # if @account.save
    #   Assignment.create(account_id: @account.id, role_id: Role.find_by(name: params[:ac_type]).id)
    #   associate_account_holder_to_account
    #   flash_message :success, t('.success')
    #   message_type = case params[:ac_type]
    #                  when 'instructor'
    #                    'new_instructor_account'
    #                  else
    #                    'new_account'
    #                  end
    #   flash_message(*Whatsapp.new(whatsapp_params(message_type)).manage_messaging)
    # else
    #   flash_message :warning, t('.warning')
    # end
    # redirect_back fallback_location: admin_clients_path
  end

  # @client = Client.new(client_params)
  # if @client.save
  #   @password = Account.password_wizard(Setting.password_length)
  #   @account = Account.new(account_params)
  #   if @account.save
  #     Assignment.create(account_id: @account.id, role_id: Role.find_by(name: 'client').id)
  #     associate_account_holder_to_account
  #     log_in @account
  #     @renewal = Renewal.new(@client)
  #     redirect_to client_shop_path @client
  #     flash_message(*Whatsapp.new(whatsapp_params('new_signup')).manage_messaging)
  #   else
  #     render 'signup', layout: 'login'
  #   end
  # else
  #   @account = Account.new
  #   render 'signup', layout: 'login'
  # end


  # password = Account.password_wizard(Setting.password_length)
  # @account = Account.new(
  #   { password:, password_confirmation: password,
  #     activated: true, ac_type: 'client', email: client.email }
  # )
  # return [[:warning, I18n.t('admin.accounts.create.warning')]] unless @account.save

  # # return to #update when sorted out whatsapp validation. New account failure if whatsapp nil (alternatively set modifier_is_client to false)
  # Assignment.create(account_id: @account.id, role_id: Role.find_by(name: 'client').id)
  # client.update(account_id: @account.id)
  # # client.update_column(:account_id, @account.id)
  # flash_for_account = :success, I18n.t('admin.accounts.create.success')
  # # https://stackoverflow.com/questions/18071374/pass-rails-error-message-from-model-to-controller
  # flash_for_whatsapp = Whatsapp.new(receiver: client, message_type: 'new_account',
  #                                   variable_contents: { password: }).manage_messaging
  # [flash_for_account, flash_for_whatsapp] # an array of arrays

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
    password = AccountCreator.password_wizard(Setting.password_length)
    @account.update(password: password, password_confirmation: password)
    flash_message(*Whatsapp.new(whatsapp_params('password_reset', password)).manage_messaging)
    redirect_back fallback_location: admin_clients_path
  end

  def password_reset_superadmin_of_admin
    passwords_the_same = (password_update_params[:new_password] == password_update_params[:new_password_confirmation])
    @account.errors.add(:base, 'passwords not the same') unless passwords_the_same
    if passwords_the_same && @account.update(password: password_update_params[:new_password], password_confirmation: password_update_params[:new_password])
      flash_message :success, t('.success')
    else
      flash[:warning] = "Update failed. Passwords either don't match or too short (min 6 characters)"
     end
    redirect_to admin_accounts_path
  end

  def password_reset_client_of_client
    passwords_the_same = (password_update_params[:new_password] == password_update_params[:new_password_confirmation])
    @account.errors.add(:base, 'passwords not the same') unless passwords_the_same
    if passwords_the_same && @account.update(password: password_update_params[:new_password], password_confirmation: password_update_params[:new_password])
      flash_message :success, t('.success')
      redirect_back fallback_location: login_path
    else
      # reformat - this code is reused in show method of clients controller
      @client = @account.client
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
    only_certain_account_types_can_be_made_here
    only_superadmin_makes_partner_accounts
  end

  def only_certain_account_types_can_be_made_here
    # administrator accounts cannot be created through the app
    return if %w[client instructor partner].include?(params[:ac_type])

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
    # reformat
    @account_holder = Client.where(id: params[:client_id]).first if params[:ac_type] == 'client'
    @account_holder = Instructor.where(id: params[:instructor_id]).first if params[:ac_type] == 'instructor'
    @account_holder = Partner.where(id: params[:partner_id]).first if params[:ac_type] == 'partner'
    (redirect_to(login_path) && return) if @account_holder.nil?
  end

  def set_account
    @account = Account.find(params[:id])
    @account_holder = @account.client
  end

  def account_params
    params.permit(:email, :ac_type).merge(account_holder: @account_holder)
  end

  def password_update_params
    params.require(:account).permit(:new_password, :new_password_confirmation, :requested_by)
  end

  def whatsapp_params(message_type, password)
    { receiver: @account_holder,
      message_type:,
      variable_contents: { first_name: @account_holder.first_name, email: @account_holder.email, password: } }
  end
end
