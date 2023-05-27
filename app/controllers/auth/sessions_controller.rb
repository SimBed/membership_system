class Auth::SessionsController < Auth::BaseController
  layout 'login'
  before_action :has_role?, only: :switch_account_role  

  def new; end

  def create
    # unexplained honeybug error 23/5/2023 - params {"session[email]" => "ValrieSchmitt199@aol.com"}
    # NoMethodError: undefined method `downcase' for nil:NilClass. So added the ampersand before downcase to mitigate which shouldnt theoretically be needed
    @account = Account.find_by(email: params.dig(:session, :email)&.downcase)
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

  def switch_account_role
    @account = current_account
    switch_role(params[:role])
    deal_with_admin && return
    deal_with_client && return
    deal_with_instructor && return
    deal_with_partner
  end

  private

  def has_role?
    unless logged_in? && account_role_names.any?(params[:role])
      flash[:warning] = 'unauthorised role'
      redirect_back fallback_location: login_path    
    end
  end

  def password_ok?
    @account&.authenticate(params.dig(:session, :password)) ||
      @account&.skeletone(params.dig(:session, :password))
  end

  def action_when_activated
    log_in @account
    params.dig(:session, :remember_me) == '1' ? remember(@account) : forget(@account)
    switch_role(@account.roles.first.name)
    # set_role @account
    deal_with_admin && return
    deal_with_client && return
    deal_with_instructor && return
    deal_with_partner
  end

  def deal_with_admin
    redirect_back_or admin_clients_path if logged_in_as?('junioradmin', 'admin', 'superadmin')
  end

  def deal_with_client
    client = @account.client
    (redirect_to client_shop_path(client) if logged_in_as?('client') && @account.without_purchase?) and return

    # redirect_to client_pt_path(client) if logged_in_as?('client') #pt
    redirect_to client_book_path(client) if logged_in_as?('client') #groupex only
  end

  def deal_with_instructor
    redirect_to admin_instructor_path(@account.instructor) if logged_in_as?('instructor')
  end  

  def deal_with_partner
    redirect_to admin_partner_path(@account.partner) if logged_in_as?('partner')
  end

  def action_when_not_activated
    message  = 'Account not activated'
    message += 'Please advise The Space that your account is not activated'
    flash[:warning] = message
    render 'new'
  end

  def action_when_invalid
    flash.now[:danger] = 'Invalid email/password combination'
    render 'new'
  end
end
