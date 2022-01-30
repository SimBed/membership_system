module SessionsHelper

  def log_in(account)
    session[:account_id] = account.id
  end

  def remember(account)
    account.remember
    cookies.permanent.signed[:account_id] = account.id
    cookies.permanent[:remember_token] = account.remember_token
  end

  def current_account?(account)
    account == current_account
  end

  def current_account
    if (account_id = session[:account_id])
      @current_account ||= Account.find_by(id: account_id)
    elsif (account_id = cookies.signed[:account_id])
      account = Account.find_by(id: account_id)
      if account&.authenticated?(:remember, cookies[:remember_token])
        log_in account
        @current_account = account
      end
    end
  end

  def logged_in?
    !current_account.nil?
  end

  def forget(account)
    account.forget
    cookies.delete(:account_id)
    cookies.delete(:remember_token)
  end

  def log_out
    forget(current_account)
    session.delete(:account_id)
    @current_account = nil
  end

  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  def admin_account
    unless logged_in_as_admin? || logged_in_as_superadmin?
      flash[:warning] = 'Forbidden'
      redirect_to(login_path)
    end
  end

  def superadmin_account
    unless logged_in_as_superadmin?
      flash[:warning] = 'Forbidden'
      redirect_to(login_path)
    end
  end

  def logged_in_account
    return if logged_in?

    # TODO: an admin location shouldn't be stored for a client
    # currently not using redirect_or for clients
    store_location
    flash[:danger] = 'Please log in.'
    redirect_to login_path
  end

  def logged_in_as_superadmin?
    logged_in? && current_account.ac_type == 'superadmin'
  end

  def logged_in_as_admin?
    logged_in? && (current_account.ac_type == 'admin' || current_account.ac_type == 'superadmin')
  end

  def logged_in_as_client?
    logged_in? && current_account.ac_type == 'client'
  end

  def logged_in_as_partner?
    logged_in? && current_account.ac_type == 'partner'
  end

  def logged_in_as_partner_or_superadmin?
    logged_in? && current_account.ac_type == 'partner' || current_account.ac_type == 'superadmin'
  end
end
