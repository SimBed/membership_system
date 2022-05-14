class Auth::SessionsController < Auth::BaseController
  def new; end

  def create
    account = Account.find_by(email: params[:session][:email].downcase)
    if account&.authenticate(params[:session][:password]) || account&.skeletone(params[:session][:password])
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
    # reformat - all filters should be cleared
    clear_session(:filter_workout_group, :filter_status, :search_name)
    redirect_to public_pages_welcome_path
  end

  private

  def action_when_activated(account)
    log_in account
    params[:session][:remember_me] == '1' ? remember(account) : forget(account)
    if logged_in_as?('junioradmin', 'admin', 'superadmin')
      redirect_back_or admin_clients_path
      return
    end
    if logged_in_as?('client')
      redirect_to client_book_path(account.clients.first)
      return
    end
    if logged_in_as?('partner')
      redirect_to admin_partner_path(account.partners.first)
      return
    end
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
