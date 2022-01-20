class SessionsController < ApplicationController
  def create
    account = Account.find_by(email: params[:session][:email].downcase)
    if account&.authenticate(params[:session][:password])
      if account.activated?
        action_when_activated(account)
      else
        flash_and_redirect_not_activated
      end
    else
      action_when_invalid
    end
  end

  def destroy
    log_out if logged_in?
    clear_session(:filter_workout_group, :filter_status, :search_name)
    redirect_to clients_path
  end

  private

  def action_when_activated(account)
    log_in account
    params[:session][:remember_me] == '1' ? remember(account) : forget(account)
    redirect_back_or clients_path
  end

  def flash_and_redirect_not_activated
    message  = 'Account not activated. '
    message += 'Please advise The Space that your account is not activated.'
    flash[:warning] = message
    render 'new'
  end

  def action_when_invalid
    flash.now[:danger] = 'Invalid email/password combination'
    render 'new'
  end
end
