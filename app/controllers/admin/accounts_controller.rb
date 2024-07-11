class Admin::AccountsController < Admin::BaseController
  before_action :correct_credentials, only: [:create]
  before_action :set_account_holder, only: [:create]
  before_action :set_account, only: [:update, :destroy, :show]
  skip_before_action :admin_account, only: [:index, :update, :destroy]
  before_action :correct_account_or_junioradmin, only: [:update]
  before_action :superadmin_account, only: [:index, :destroy]

  def create
    outcome = AccountCreator.new(account_params).create
    if outcome.success?
      flash_message :success, t('.success'), true # want the true for client as in this case we render rather than redirect
      flash_message(*Whatsapp.new(whatsapp_params('new_account', outcome.password)).manage_messaging)
    else
      flash_message :warning, t('.warning')
    end
    respond_to do |format|
      format.html { redirect_back fallback_location: clients_path }
      format.turbo_stream {render :update}
    end
  end

  def update
    password = AccountCreator.password_wizard(Setting.password_length)
    @account.update(password:, password_confirmation: password)
    flash_message(*Whatsapp.new(whatsapp_params('password_reset', password)).manage_messaging, true)
    flash_message :success, 'whatsapp not sent in development (but would be in production)' if Rails.env.development?
    # render partial: 'admin/clients/manage_account', locals: {client: @account.client}
    respond_to do |format|
      format.html { redirect_back fallback_location: clients_path }
      format.turbo_stream
    end
  end

  def destroy
    @account.clean_up
    # without the reload, when we pass locals: {client: @account_holder} in update.turbo_stream, it is still the account_holder with an account held in memory and so
    # in _manage_account.html, client.account would not return nil, even though the the account has been destroyed and the client no longer has has an account. 
    @account_holder.reload
    flash_message :success, t('.success'), true
    respond_to do |format|
      format.html { redirect_back fallback_location: clients_path }
      format.turbo_stream {render :update}
    end
  end

  private

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
  end

  def only_certain_account_types_can_be_made_here
    @role_name = params[:role_name] 
    return if %w[client instructor].include?(@role_name)
    flash[:warning] = t('.warning')
    redirect_to(login_path) && return
  end

  def set_account_holder
    @account_type = account_params[:role_name]
    role_classs = @account_type.camelcase.constantize
    @account_holder = role_classs.where(id: account_params[:id]).first
    (redirect_to(login_path) && return) if @account_holder.nil?
    # NOTE: this wont do what you hope beacuse turbo demands a response with the requisite turbo_frame
    rescue Exception
    # log_out if logged_in?
    flash[:danger] = "Please don't mess with the system"
    redirect_to login_path
  end

  def set_account
    @account = Account.find(params[:id])
    @account_holder = @account.client
    @account_type = @account.priority_role.name
  end

  def account_params
    params.permit(:email, :id, :role_name).merge(account_holder: @account_holder)
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
