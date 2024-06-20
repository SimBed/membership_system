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
      if %w[instructor].include?(@account_type)
        flash_message :success, t('.success') # dont want the true for flash.now for instructor as in this case we redirect rather than render
        flash_message(*Whatsapp.new(whatsapp_params('new_instructor_account', outcome.password)).manage_messaging)
      else
        flash_message :success, t('.success'), true # want the true for client as in this case we render rather than redirect
        flash_message(*Whatsapp.new(whatsapp_params('new_account', outcome.password)).manage_messaging)
      end
    else
      flash_message :warning, t('.warning')
    end
    # render partial: 'admin/clients/manage_account', locals: {client: @account_holder} 
    # redirect_back fallback_location: clients_path
    #NOTE: update for instructor/admin - needs a different turbo update
    if %w[client].include?(@account_type) 
      respond_to do |format|
        format.html { redirect_back fallback_location: clients_path }
        format.turbo_stream {render :update}
      end
    else
      # respond_to do |format|
      #   format.html { redirect_back fallback_location: instructors_path }
      #   format.turbo_stream {render 'admin/instructors/index'}
      # end
      redirect_to instructors_path
    end
  end

  def update
    # NOTE: needs cleaning up - not that it will happen but if superadmin request for admin gets routed through here, it will incorrectly land on password_reset_client_of_client
    if params[:account].nil? # means request came from admin link
      password_reset_admin_of_client
    # elsif params[:account][:requested_by] == 'superadmin_of_admin'
    #   (redirect_to login_path and return) unless logged_in_as?('superadmin')
    #   password_reset_superadmin_of_admin
    else
      password_reset_client_of_client
    end
  end

  def destroy
    # redirection = @account_holder.is_a?(Client) ? client_path(@account_holder) : employee_accounts_path
    @account.clean_up
    # redirect_to redirection
    if @account_type == "client"
      flash_message :success, t('.success'), true
      respond_to do |format|
        format.html { redirect_back fallback_location: clients_path }
        format.turbo_stream {render :update}
      end
    else # admin or instructor
      flash_message :success, t('.success')
      redirect_to employee_accounts_path
    end

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
        atendances: @client.bookings.attended.size,
        last_counted_class: @client.last_counted_class,
        date_created: @client.created_at,
        date_last_purchase_expiry: @client.last_purchase&.expiry_date
      }
      render 'client/data_pages/profile', layout: 'client'
    end
  end

  private

  def password_reset_admin_of_client
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
    # administrator accounts cannot be created through the app
    return if %w[client instructor].include?(@role_name)
    flash[:warning] = t('.warning')
    redirect_to(login_path) && return
  end

  def set_account_holder
    role_classs = account_params[:role_name].camelcase.constantize
    @account_holder = role_classs.where(id: account_params[:id]).first
    (redirect_to(login_path) && return) if @account_holder.nil?
    # NOTE: this wont do whay you hope beacuse turbo demands a response with the requisite turbo_frame
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
