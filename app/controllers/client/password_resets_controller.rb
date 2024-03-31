class Client::PasswordResetsController < ApplicationController
  layout 'login'
  before_action :set_account,   only: [:edit, :update]
  before_action :valid_account, only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]

  def new; end

  def edit; end

  def create
    @account = Account.find_by(email: params[:password_reset][:email].downcase)
    if @account
      @account.create_reset_digest
      @account.send_password_reset_email
      flash[:info] = t('.info')
      redirect_to login_path
    else
      flash.now[:danger] = t('.danger')
      # https://stackoverflow.com/questions/70400958/error-form-responses-must-redirect-to-another-location
      # render 'new'
      render 'new', status: :unprocessable_entity # 422
    end
  end

  def update
    if params[:account][:password].empty?
      @account.errors.add(:password, "can't be empty")
      render 'edit'
    elsif @account.update(account_params)
      log_in @account
      # MH 12.22
      # guard against public computer situation where pressing the back button on the browser gives access to the same password reset form (containing the reset_token )
      @account.update_column(:reset_digest, nil)
      flash[:success] = 'Password has been reset.'
      send_to_correct_page_for_role
    else
      render 'edit'
    end
  end

  # through UI - no mailer involved
  def password_change
    @account = Account.find(params[:id])    
    passwords_the_same = (password_change_params[:new_password] == password_change_params[:new_password_confirmation])
    @account.errors.add(:base, 'passwords not the same') unless passwords_the_same
    if passwords_the_same && @account.update(password: password_change_params[:new_password], password_confirmation: password_change_params[:new_password])
      flash_message :success, t('.success')
      # redirect_back fallback_location: login_path
      redirect_to client_profile_path(@account.client)
    else
      # reformat - this code is reused in show method of clients controller
      @client = @account.client
      @client_hash = {
        attendances: @client.attendances.attended.size,
        last_counted_class: @client.last_counted_class,
        date_created: @client.created_at,
        date_last_purchase_expiry: @client.last_purchase&.expiry_date
      }
      render 'client/data_pages/profile', layout: 'client'
    end
  end  

  private

  def password_change_params
    params.permit(:new_password, :new_password_confirmation)
  end

  def account_params
    params.require(:account).permit(:password, :password_confirmation)
  end

  def set_account
    @account = Account.find_by(email: params[:email])
  end

  def valid_account
    unless @account&.activated? &&
           @account&.authenticated?(:reset, params[:id])
      redirect_to root_url
    end
  end

  def check_expiration
    return unless @account.password_reset_expired?

    flash[:danger] = 'Password reset has expired.'
    redirect_to new_client_password_reset_url
  end
end
