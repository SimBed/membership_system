class Auth::SessionsController < Auth::BaseController
  def new; end

  def create
    @account = Account.find_by(email: params.dig(:session, :email).downcase)
    if password_ok?
      if @account.activated?
        action_when_activated
      else
        action_when_not_activated
      end
    else
      action_when_invalid
    end
  end

  def destroy
    log_out if logged_in?
    # reformat - all filters should be cleared
    clear_session(:filter_workout_group, :filter_statuses, :search_name)
    redirect_to root_path
  end

  private

  def password_ok?
    @account&.authenticate(params.dig(:session, :password)) ||
      @account&.skeletone(params.dig(:session, :password))
  end

  def action_when_activated
    log_in @account
    params.dig(:session, :remember_me) == '1' ? remember(@account) : forget(@account)
    deal_with_admin && return
    deal_with_client && return
    deal_with_partner
  end

  def deal_with_admin
    redirect_back_or admin_clients_path if logged_in_as?('junioradmin', 'admin', 'superadmin')
  end

  def deal_with_client
    redirect_to client_book_path(@account.clients.first) if logged_in_as?('client')
  end

  def deal_with_partner
    redirect_to admin_partner_path(@account.partners.first) if logged_in_as?('partner')
  end

  def action_when_not_activated
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
