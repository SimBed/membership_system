class ApplicationController < ActionController::Base
  include ApplicationHelper
  include SessionsHelper

  # to demonstrate session deletion issue is csrf-related (randomly occurring session deletion stops when protectfromforgery is false )
  # protect_from_forgery unless false
  # https://www.ruby-forum.com/t/the-change-you-want-was-rejected-maybe-you-changed-something-you-didnt-have-access-to/183945/2
  # Added to manage a hopefully resolved CSRF error
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_token_issues

  def handle_token_issues
    flash[:warning] = 'Session expired. If this continues, please try clearing your cache.'
    redirect_to login_path
  end

  private

  def send_to_correct_page_for_ac_type
    deal_with_admin && return
    deal_with_client && return
    deal_with_instructor && return
    deal_with_partner
  end

  def deal_with_admin
    redirect_back_or admin_clients_path if logged_in_as?('junioradmin', 'admin', 'superadmin')
  end

  def deal_with_client
    begin
    (redirect_to client_shop_path(@account.client) if logged_in_as?('client') && @account.without_purchase?) and return

    # redirect_to client_pt_path(client) if logged_in_as?('client') #pt
    redirect_to client_book_path(@account.client) if logged_in_as?('client') # groupex only
    
    # the rescue is only needed because I've manually assigned a client to superadmin (for role-shifting) leaving the original account of the client
    # without a client account, so on attempted log in, @account.client is nil and things fail.
    rescue Exception
      log_out if logged_in?
      redirect_to login_path
      flash[:danger] = 'No client associated with this account. Unable to login.'
    end
  end

  def deal_with_instructor
    # default to general wkclasses page (not instructor class page) as instructors class page for instructor without commission is restricted
    redirect_to admin_wkclasses_path if logged_in_as?('instructor')
    # redirect_to admin_instructor_path(@account.instructor) if logged_in_as?('instructor')    
  end

  def deal_with_partner
    redirect_to admin_partner_path(@account.partner) if logged_in_as?('partner')
  end
end
