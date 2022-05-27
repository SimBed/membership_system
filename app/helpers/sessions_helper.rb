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
    unless logged_in_as?('admin', 'superadmin')
      flash[:warning] = 'Forbidden'
      redirect_to login_path
    end
  end

  def superadmin_account
    unless logged_in_as?('superadmin')
      flash[:warning] = 'Forbidden'
      redirect_to login_path
    end
  end

  def junioradmin_account
    unless logged_in_as?('junioradmin', 'admin', 'superadmin')
      flash[:warning] = 'Forbidden'
      redirect_to login_path
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

  def clear_session(*args)
    args.each do |session_key|
      session[session_key] = nil
    end
  end

  def set_session(*args)
    args.each do |session_key|
      session["filter_#{session_key}"] = params[session_key] || session["filter_#{session_key}"]
    end
  end

  def logged_in_as?(*ac_types)
    logged_in? && ac_types.map { |ac_type| current_account.ac_type == ac_type }.include?(true)
  end
end
