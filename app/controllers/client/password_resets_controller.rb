class Client::PasswordResetsController < ApplicationController
  layout 'login'
  before_action :set_account,   only: [:edit, :update]
  before_action :valid_account, only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]

  def new
  end

  def create
    @account = Account.find_by(email: params[:password_reset][:email].downcase)
    if @account
      @account.create_reset_digest
      @account.send_password_reset_email
      flash[:info] = "Email sent with password reset instructions"
      redirect_to login_path
    else
      flash.now[:danger] = "Email address not found"
      render 'new'
    end
  end

  def edit
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
      flash[:success] = "Password has been reset."
      send_to_correct_page_for_ac_type
    else
      render 'edit'
    end
  end

  private

    def account_params
      params.require(:account).permit(:password, :password_confirmation)
    end

    def set_account
      @account = Account.find_by(email: params[:email])
    end

    def valid_account
      unless (@account && @account.activated? &&
              @account.authenticated?(:reset, params[:id]))
        redirect_to root_url
      end
    end

    def check_expiration
      if @account.password_reset_expired?
        flash[:danger] = "Password reset has expired."
        redirect_to new_client_password_reset_url
      end
    end
    
end
