module SessionsHelper
  def log_in(account)
    session[:account_id] = account.id
    session[:role_name] = if (role_name = cookies.signed[:role_name])
                            if account.roles.include? role_name
                              role_name
                            else
                              account.roles.first.name
                            end
                          else
                            account.roles.first.name
                          end
  end

  def remember(account)
    account.remember
    cookies.permanent.signed[:account_id] = account.id
    cookies.permanent.signed[:role_name] = account.roles.first.name
    cookies.permanent[:remember_token] = account.remember_token
  end

  def forget(account)
    account.forget
    cookies.delete(:account_id)
    cookies.delete(:role_name)
    cookies.delete(:remember_token)
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
        account.logins.create(by_cookie: true) if Setting.log_each_login
        @current_account = account
      end
    end
  end

  def switch_role(role)
    session[:role_name] = role
    cookies.permanent.signed[:role_name] = role
  end

  def current_account_role_names
    current_account.roles.map(&:name)
  end

  # def current_role
  #   return unless logged_in? && current_account_role_names.any?(session[:role_name])

  #   session[:role_name]
  # end

  def current_role
    return unless logged_in?

    if (role_name = session[:role_name])
      @current_role ||= role_name
    elsif (role_name = cookies.signed[:role_name])
      @current_role = role_name
    end
  end

  def navbar_roles
    # current_role is a string
    current_account.roles - Role.where(name: current_role)
  end

  def multiple_roles?
    # current_role is a string
    navbar_roles.count.positive?
  end

  def logged_in?
    !current_account.nil?
  end

  def log_out
    forget(current_account)
    close_browser
    # session.delete(:account_id)
    # session.delete(:role_name)
    # @current_account = nil
    # @current_role = nil
  end

  def close_browser
    session.delete(:account_id)
    session.delete(:role_name)
    @current_account = nil
    @current_role = nil
  end

  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  def admin_account
    return if logged_in_as?('admin', 'superadmin')

    flash[:warning] = I18n.t(:forbidden)
    redirect_to login_path
  end

  def superadmin_account
    return if logged_in_as?('superadmin')

    flash[:warning] = I18n.t(:forbidden)
    redirect_to login_path
  end

  def junioradmin_account
    return if logged_in_as?('junioradmin', 'admin', 'superadmin')

    flash[:warning] = I18n.t(:forbidden)
    redirect_to login_path
  end

  def client_account
    return if logged_in_as?('client')

    flash[:warning] = 'Only logged-in clients can buy from the shop'
    redirect_to login_path
  end

  def junioradmin_or_instructor_account
    return if logged_in_as?('junioradmin', 'admin', 'superadmin', 'instructor')

    flash[:warning] = I18n.t(:forbidden)
    redirect_to login_path
  end

  def admin_or_instructor_account
    return if logged_in_as?('admin', 'superadmin', 'instructor')

    flash[:warning] = I18n.t(:forbidden)
    redirect_to login_path
  end

  def admin_or_instructor_or_client_account
    return if logged_in_as?('admin', 'superadmin', 'instructor', 'client')

    flash[:warning] = I18n.t(:forbidden)
    redirect_to login_path
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

  def logged_in_as?(*roles)
    logged_in? && roles.any? { |role| current_role == role }
  end
end
