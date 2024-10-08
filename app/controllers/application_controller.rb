class ApplicationController < ActionController::Base
  include Pagy::Backend
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

  def update_purchase_status(purchases)
    # this has to be done as separate requests as each calc is dependent on the previously updated attribute
    # this could be avoided and done as one update request with some reformatting of the calc methods (to include an optional argument)
    purchases.each do |p|
      orig_status = p.status
      orig_expiry_date = p.expiry_date
      p.update(start_date: p.start_date_calc)
      p.update(expiry_date: p.expiry_date_calc)
      p.update(status: p.status_calc)
      status_changed = orig_status != p.status
      expiry_earlier = expiry_earlier?(p.expiry_date, orig_expiry_date)
      # expiry_earlier = p.expiry_date.nil? ? false : orig_expiry_date > p.expiry_date
      @major_change = status_changed || expiry_earlier # if there is a major change then we will do full page reload rather than discrete turbo-frames update
      # NOTE: rider = nil would return false, so this means if p has a rider then set rider as p's rider and carry out the conditional, otherwise dont
      # NOTE: sage rubocop advice, Use == if you meant to do a comparison or wrap the expression in parentheses to indicate you meant to assign in a condition
      if (rider = p.rider_purchase)
        # the rider cant continue once the main has expired [presumed for now, policy not explicit]
        rider.update(status: 'expired', expiry_date: p.expiry_date) if p.expired? && !rider.expired?
        # conceivably the rider can be reactivated from expired if a change is made to the main that brings the main back from expired. (This is benign when main purchase changes to 'classes all booked')
        rider.update(status: rider.status_calc) if !p.expired? && status_changed
      end
      # cancel any bookings that are now outside new expiry date
      # could also cancel any pt rider bookings post main expiry, but this may cause undisproportionate business problems
      next unless expiry_earlier
      period = (p.expiry_date.advance(days: 1)..Float::INFINITY)
      post_expiry_bookings = p.bookings.during(period).booked
      post_expiry_bookings.each do |booking|
        # need to ovverride validations as by definition these are post the new expiry and so not valid
        booking.update_columns({status: 'cancelled early', amnesty: true})
        flash_message :danger, t('.booking_cancelled')
      end
    end
  end

  def cancel_bookings_during_freeze(freeze)
    freeze_period = freeze.start_date..freeze.end_date
    freeze.purchase.bookings.booked.during(freeze_period).each do |a|
      a.update(status: 'cancelled early')
      flash_message :danger, t('.booking_cancelled')
    end
  end

  def cancel_bookings_post_new_expiry(freeze)
    freeze_period = freeze.start_date..freeze.end_date
    freeze.purchase.bookings.booked.during(freeze_period).each do |a|
      a.update(status: 'cancelled early')
      flash_message :danger, t('.booking_cancelled')
    end
  end

  def notify_waiting_list(wkclass, triggered_by: 'admin')
    waitings = wkclass.waitings
    return if waitings.empty? || wkclass.in_the_past? || wkclass.at_capacity?

    waitings.each do |waiting|
      flash_message(*Whatsapp.new({ receiver: waiting.purchase.client,
                                    message_type: 'waiting_list_blast',
                                    triggered_by:,
                                    variable_contents: { wkclass_name: wkclass.name,
                                                         date_time: wkclass.date_time_short } }).manage_messaging)
    end
  end

  private

  def send_to_correct_page_for_role
    deal_with_admin && return
    deal_with_client && return
    deal_with_instructor

    # the rescue is only needed because I've manually assigned a client to superadmin (for role-shifting) leaving the original account of the client
    # without a client account, so on attempted log in, @account.client (in #deal_with_client) is nil and things fail.
    rescue Exception
      log_out if logged_in?
      redirect_to login_path
      flash[:danger] = 'No client associated with this account. Unable to login.'    
  end

  def deal_with_admin
    redirect_back_or clients_path if logged_in_as?('junioradmin', 'admin', 'superadmin')
  end

  def deal_with_client
    return unless logged_in_as?('client')

    client = @account.client
    (redirect_to client_shop_path(client) if @account.without_purchase?) and return

    # temporary - ultimately no client without a declaration may book, in short-term existing clients with old declarations can continue to book
    (redirect_to new_client_declaration_path(client) if client.not_yet_booked? && !client.declaration) and return 

    redirect_to client_bookings_path(client)
  end

  def deal_with_instructor
    if logged_in_as?('instructor')
      if @account.instructor.employee?
        redirect_to wkclasses_path
      else
        redirect_to instructor_path(@account.instructor)
      end
    end
  end

  def set_admin_status
    @superadmin = logged_in_as?('superadmin')
    @admin_plus = logged_in_as?('admin', 'superadmin')
    @junioradmin_plus = logged_in_as?('junioradmin', 'admin', 'superadmin')
    @junioradmin = logged_in_as?('junioradmin')
  end

  def expiry_earlier?(current_expiry_date, orig_expiry_date)
    return false if current_expiry_date.nil? || orig_expiry_date.nil?

    orig_expiry_date > current_expiry_date
  end
end