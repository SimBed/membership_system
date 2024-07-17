class Auth::SessionsController < Auth::BaseController
  layout 'login'
  before_action :has_role?, only: :switch_account_role

  def new
    # https://www.ducktypelabs.com/turbo-break-out-and-redirect/ turbo_page_requires_reload
    # flash.keep if turbo_frame_request?
  end

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
    deal_with_instructor
  end

  def close_the_browser
    close_browser
    redirect_to root_path
  end

  private

  def has_role?
    # NOTE: should be return not return false??
    return false if logged_in? && current_account_role_names.any?(params[:role])

    flash[:warning] = 'unauthorised role'
    redirect_back fallback_location: login_path
  end

  def password_ok?
    @account&.authenticate(params.dig(:session, :password)) ||
      @account&.skeletone(params.dig(:session, :password))
  end

  def action_when_activated
    log_in @account
    @account.logins.create
    # params.dig(:session, :remember_me) == '1' ? remember(@account) : forget(@account)
    remember(@account) #unless cookies.signed[:account_id] #if @account.remember_digest.nil?
    send_to_correct_page_for_role
  end

  def action_when_not_activated
    flash_message :warning, t('.account_not_activated')
    render 'new'
  end

  def action_when_invalid
    flash_message :danger, t('.action_when_invalid'), true
    render 'new'
  end
end
