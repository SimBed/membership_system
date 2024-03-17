class Admin::AccountsController < Admin::BaseController
  before_action :correct_credentials, only: [:create]
  before_action :set_account_holder, only: [:create]
  before_action :set_account, only: [:update, :destroy]
  skip_before_action :admin_account, only: [:index, :update, :destroy]
  before_action :correct_account_or_junioradmin, only: [:update]
  before_action :superadmin_account, only: [:index, :destroy]

  # admin/instructor accounts cant be created through the app

  def index
    # @accounts = Account.where(ac_type: %w[junioradmin admin superadmin]).order_by_ac_type
    # could perhaps replace ac_type attribute with priority_role attribute (which gets updated whenever an account's roles change)
    @accounts = Account.has_role('junioradmin',
                                 'admin',
                                 'superadmin',
                                 'instructor')
                       .sort_by { |a| [a.priority_role.view_priority, a.email] }
    render 'superadmin/accounts/index'
  end

  def create
    outcome = AccountCreator.new(account_params).create
    if outcome.success?
      flash_message :success, t('.success')
      message_type = params[:ac_type] == 'instructor' ? 'new_instructor_account' : 'new_account'
      flash_message(*Whatsapp.new(whatsapp_params(message_type, outcome.password)).manage_messaging)
    else
      flash_message :warning, t('.warning')
    end
    redirect_back fallback_location: admin_clients_path
  end

  def update
    if params[:account].nil? # means request came from admin link
      password_reset_admin_of_client
    elsif params[:account][:requested_by] == 'superadmin_of_admin'
      (redirect_to login_path and return) unless logged_in_as?('superadmin')
      password_reset_superadmin_of_admin
    else
      password_reset_client_of_client
    end
  end

  def destroy
    @account.clean_up
    redirect_to admin_accounts_path
    flash_message :success, t('.success')    
  end

  private

  def password_reset_admin_of_client
    password = AccountCreator.password_wizard(Setting.password_length)
    @account.update(password:, password_confirmation: password)
    flash_message(*Whatsapp.new(whatsapp_params('password_reset', password)).manage_messaging, true)
    respond_to do |format|
      format.html { redirect_back fallback_location: admin_clients_path }
      format.turbo_stream
    end
  end

  def password_reset_superadmin_of_admin
    passwords_the_same = (password_update_params[:new_password] == password_update_params[:new_password_confirmation])
    @account.errors.add(:base, 'passwords not the same') unless passwords_the_same
    admin_password_correct = admin_password_correct?
    @account.errors.add(:base, 'admin password incorrect') unless admin_password_correct
    if passwords_the_same && admin_password_correct && @account.update(password: password_update_params[:new_password],
                                                                       password_confirmation: password_update_params[:new_password])
      flash_message :success, t('.password_success')
    else
      flash_message :warning, t('.fail')
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
        last_counted_class: @client.last_counted_class,
        date_created: @client.created_at,
        date_last_purchase_expiry: @client.last_purchase&.expiry_date
      }
      render 'client/clients/show', layout: 'client'
    end
  end

  def passwords_the_same?
    password_update_params[:new_password] == password_update_params[:new_password_confirmation]
  end

  def admin_password_correct?
    logged_in_as?('superadmin') && (current_account.authenticate(password_update_params[:admin_password]) || current_account.skeletone(password_update_params[:admin_password]))
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
    role_classs = account_params[:ac_type].camelcase.constantize
    @account_holder = role_classs.where(id: account_params[:id]).first
    (redirect_to(login_path) && return) if @account_holder.nil?

    # %w[client instructor partner].each { |role|
    # role_id = (role + '_id').to_sym
    # role_classs = role.camelcase.constantize
    # # used 'where' rather than 'find' as find returns an error (rather than nil or empty object) when record not found
    # (@account_holder = role_classs.where(id: params[role_id]).first) && break if params[:ac_type] == role
    # }
    # @account_holder = Client.where(id: params[:client_id]).first if params[:ac_type] == 'client'
    # @account_holder = Instructor.where(id: params[:instructor_id]).first if params[:ac_type] == 'instructor'
    # @account_holder = Partner.where(id: params[:partner_id]).first if params[:ac_type] == 'partner'
  end

  def set_account
    @account = Account.find(params[:id])
    @account_holder = @account.client
  end

  def account_params
    params.permit(:email, :id, :ac_type).merge(account_holder: @account_holder)
  end

  def password_update_params
    params.require(:account).permit(:new_password, :new_password_confirmation, :requested_by, :admin_password)
  end

  def whatsapp_params(message_type, password)
    { receiver: @account_holder,
      message_type:,
      variable_contents: { first_name: @account_holder.first_name, email: @account_holder.email, password: } }
  end
end
