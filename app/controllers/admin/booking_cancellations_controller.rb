class Admin::BookingCancellationsController < Admin::BaseController
  include BookingsHelper
  skip_before_action :admin_account
  before_action :set_booking
  before_action :correct_account_or_junioradmin_or_instructor_account
  before_action :set_booking_day, if: -> { client? }
  before_action :provisionally_expired
  before_action :modifiable_status
  before_action :already_committed
  before_action :reached_max_capacity
  before_action :reached_max_amendments
  after_action -> { update_purchase_status([@purchase]) }

  def update
    @purchase = @booking.purchase
    @wkclass = @booking.wkclass
    update_by_client if client?
    return unless logged_in_as?('junioradmin', 'admin', 'superadmin', 'instructor')

    result = AdminBookingUpdater.new(booking: @booking, wkclass: @wkclass, new_status: booking_status_params[:status]).update
    flash_message(*result.flash_array)
    update_purchase_status([@purchase]) if result.penalty_change?
    return unless result.success?

    remove_from_waiting_list
    notify_waiting_list(@wkclass, triggered_by: 'admin') if ['cancelled early', 'cancelled late'].include? booking_status_params[:status]
    handle_admin_update_response
  end

  def update_by_client
    basic_data('client')
    action_client_update_too_late && return if @time_of_request == 'too late'

    send "set_data_client_#{@time_of_request}_cancel"
    if @booking.update(status: @updated_status)
      action_client_update_success

      handle_client_update_response
    else
      flash_client_update_fail
    end
  end

  private

  def extra_benefits_after_change?
    late_cancels_max = Setting.amnesty_limit[@purchase.product_style][:late_cancels][@purchase.product_type]
    no_shows_max = Setting.amnesty_limit[@purchase.product_style][:no_shows][@purchase.product_type]
    has_late_cancels_amnesty = @purchase.late_cancels < late_cancels_max
    has_no_show_amnesty = @purchase.no_shows < no_shows_max
    amnesty_when_changed = true
    if (params[:booking][:status] == 'no show' && !has_no_show_amnesty) ||
       (params[:booking][:status] == 'cancelled late' && !has_late_cancels_amnesty)
      amnesty_when_changed = false
    end
    return true if @booking.amnesty? && !amnesty_when_changed

    false
  end

  def client?
    logged_in_as?('client')
  end

  # so day on slider shown doesn't revert to default on response
  def set_booking_day
    default_booking_day = 0
    session[:booking_day] = params[:booking_day] || session[:booking_day] || default_booking_day
  end

  def time_of_request
    # only applies to client requests. Admin modifies status directly
    # return 'na' if admin_modification?
    case @wkclass.start_time - Time.zone.now
    when 2.hours.to_i..Float::INFINITY
      'early'
    when 0..2.hours.to_i
      'late'
    else
      'too late'
    end
  end

  def set_data_client_early_cancel
    if @original_status == 'booked'
      @updated_status = 'cancelled early'
      @early_cancellation_by_client = true
    else
      @updated_status = 'booked'
    end
  end

  def set_data_client_late_cancel
    if @original_status == 'booked'
      @updated_status = 'cancelled late'
      @late_cancellation_by_client = true
    else
      @updated_status = 'booked'
    end
  end

  def action_client_update_too_late
    flash_hash = booking_flash_hash[:update][:too_late]
    flash_message flash_hash[:colour], (send flash_hash[:message], true, @wkclass_name)
    # flash[flash_hash[:colour]] = send flash_hash[:message], true, @wkclass_name
    redirect_to client_book_path(@client)
  end

  def action_client_update_success
    @booking.increment!(:amendment_count)
    if @late_cancellation_by_client
      action_cancelled_late
    elsif @early_cancellation_by_client
      action_cancelled_early
    else # a rebook (and bookings always count)
      @booking.update(amnesty: false)
      handle_freeze
    end
    remove_from_waiting_list
    notify_waiting_list(@wkclass, triggered_by: 'client')
  end

  def action_cancelled_late
    @purchase.increment!(:late_cancels)
    late_cancels_max = Setting.amnesty_limit[@purchase.product_style][:late_cancels][@purchase.product_type]
    if @purchase.reload.late_cancels > late_cancels_max
      late_cancellation_penalty @purchase.product_type, penalty: true
      # amnesty remains false from earlier booking
    else
      late_cancellation_penalty @purchase.product_type, penalty: false
      @booking.update(amnesty: true)
    end
  end

  def action_cancelled_early
    @purchase.increment!(:early_cancels)
    @booking.update(amnesty: true)
  end

  def handle_client_update_response
    set_atendances
    flash_client_update_success
    # pass which section the request came from to render the correct turbo_stream to update the correct table opengym/group/my-bookings
    # pass limited as well, as if the request is from my_bookings the turbo stream needs to now whether to update group table or opengym table
    # limited not used in the end (can be deleted). When a mybooking is cancelled, update both opengym and group. If you dust update the impacted table, then when the day of the cancelled class is different from
    # the day currently selected, there will be inconsistency between the day shown and the non-impacted listing
    redirect_to client_book_path(@client, booking_section: params[:booking_section], limited: @wkclass.workout.limited, major_change: @major_change) # pass whether a major change occurred to trigger either a full page reload or just a discrete turbo_frame
  end

  # https://stackoverflow.com/questions/49952991/add-a-line-break-in-a-flash-notice-rails-controller
  # adding newline to flash surprisingly awkward. Adapted application.html.erb per 'dirty' suggestion.
  def flash_client_update_success
    flash_type = if @original_status == 'booked'
                   if @time_of_request == 'early'
                     :cancel_early
                   else # late
                     @penalty_given ? :cancel_late_no_amnesty : :cancel_late_amnesty
                   end
                 else # cancelled to booked
                   :successful
                 end
    set_flash(booking_flash_hash[:update], flash_type)
  end

  def remove_from_waiting_list
    @client.waiting_list_for(@wkclass).destroy if @client.on_waiting_list_for?(@wkclass)
  end

  def handle_admin_update_response
    set_atendances
    flash_message :success, t('.success', name: @booking.client_name, status: @booking.status)
    redirect_to wkclass_path(@booking.wkclass, link_from: params[:booking][:link_from], page: params[:booking][:page])
  end

  def set_atendances
    @atendances = @wkclass.atendances.order_by_status
    @non_atendances_no_amnesty = @wkclass.non_atendances.no_amnesty.order_by_status
    @non_atendances_amnesty = @wkclass.non_atendances.amnesty.order_by_status
  end

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def handle_freeze
    wkclass_datetime = @booking.wkclass.start_time
    # unlikley to be more than 1, but you never know
    applicable_freezes = @purchase.freezes_cover(wkclass_datetime)
    return if applicable_freezes.empty?

    applicable_freezes.each do |f|
      # wish to bypass validation, else would just use update method
      f.end_date = wkclass_datetime.advance(days: -1).to_date
      f.save(validate: false)
    end
  end

  def basic_data(account)
    @wkclass_name = @wkclass.name
    @wkclass_day = @wkclass.day_of_week
    if account == 'client'
      @time_of_request = time_of_request
      @original_status = @booking.status
    else # admin
      @client_name = @booking.client_name
    end
  end

  def set_flash(hash, event)
    flash_message hash.dig(event, :colour), (send hash.dig(event, :message), @wkclass_name, @wkclass_day)
  end

  def correct_account_or_junioradmin_or_instructor_account
    @client = @booking.client
    return if current_account?(@client&.account) || logged_in_as?('junioradmin', 'admin', 'superadmin', 'instructor')

    flash_message :warning, t('.warning')
    redirect_to login_path
  end

  def provisionally_expired
    # eg class shown as bookable, then purchase becomes provsionally expired due to booking of a different class
    # either on different browser or by admin, then attempting to book the class shown as bookable on first browser should fail
    if new_booking?
      handle_provisionally_expired_new_booking
    else # update
      data_items_provisionally_expired(new_booking: false)
      if @purchase.provisionally_expired?
        action_client_rebook_cancellation_when_prov_expired if client? && @booking.status != 'booked'
        # if the change results in an extra class or validity term reduction
        action_admin_rebook_cancellation_when_prov_expired if logged_in_as?('junioradmin', 'admin', 'superadmin') && extra_benefits_after_change?
      end
    end
  end

  # example1 - browser loads, time passes, client logged as no show,
  # client through browser sends request to cancel booking
  # example2 - non-browser request to update 'attended' to 'cancelled early'
  def modifiable_status
    # client can never modify attended or no show
    return if ['attended', 'no show'].exclude?(@booking.status) || admin_modification?

    flash_hash = booking_flash_hash[:update][:unmodifiable]
    flash_message flash_hash[:colour], (send flash_hash[:message], @booking.status)
    # flash[flash_hash[:colour]] =
    #   send flash_hash[:message], @booking.status
    redirect_to client_book_path(@client)
  end

  def already_committed
    set_wkclass_and_booking_type
    return unless @purchase.restricted_on?(@wkclass)

    flash_hash = booking_flash_hash.dig(@booking_type, :daily_limit_met)
    flash_message flash_hash[:colour], (send flash_hash[:message])
    # flash_hash[:colour] = send flash_hash[:message]
    if client?
      redirect_to client_book_path(@client)
    else # must be admin
      redirect_to wkclass_path(@wkclass)
    end
  end

  def reached_max_capacity
    return if admin_modification?

    set_wkclass_and_booking_type
    return unless @wkclass.at_capacity?

    action_fully_booked(@booking_type) if new_booking? || ['cancelled early',
                                                           'cancelled late'].include?(@booking.status)
  end

  def action_fully_booked(booking_type)
    flash_hash = booking_flash_hash[booking_type][:fully_booked]
    flash_message flash_hash[:colour], (send flash_hash[:message], @rebooking)
    # flash[flash_hash[:colour]] = send flash_hash[:message], @rebooking
    redirect_to client_book_path(@client)
  end

  def reached_max_amendments
    return unless client? && @booking.maxed_out_amendments?

    flash_message booking_flash_hash[:update][:prior_amendments][:colour],
                  (send booking_flash_hash[:update][:prior_amendments][:message])
    redirect_to client_book_path(@client)
  end

  def new_booking?
    return true if request.post?

    false
  end

  def data_items_provisionally_expired(new_booking: true)
    if new_booking
      @purchase = Purchase.find(params.dig(:booking, :purchase_id).to_i)
      @wkclass = Wkclass.find(params.dig(:booking, :wkclass_id).to_i)
    else # update
      @purchase = @booking.purchase
    end
  end

  def late_cancellation_penalty(package_type, penalty: true)
    # no more than one penalty per booking
    return unless package_type == :unlimited_package && @booking.penalty.nil?

    return unless penalty

    Penalty.create({ purchase_id: @purchase.id, booking_id: @booking.id, amount: 1,
                     reason: 'late cancellation' })
    update_purchase_status([@purchase])
    @penalty_given = true # for the flash
    # no longer whatsapp as the flash will inform
  end

  def admin_modification?
    return true if logged_in_as?('junioradmin', 'admin', 'superadmin', 'instructor')

    false
  end

  def set_wkclass_and_booking_type
    if new_booking?
      @booking_type = :booking
      @rebooking = false
      @wkclass = Wkclass.find(params[:booking][:wkclass_id].to_i)
      @purchase = Purchase.find(params.dig(:booking, :purchase_id).to_i)
    else
      @booking_type = :update
      @rebooking = true
      @wkclass = @booking.wkclass
      @purchase = @booking.purchase
    end
  end

  def action_client_rebook_cancellation_when_prov_expired
    flash_message :warning,
                  ['The maximum number of classes has already been booked.',
                   'Renew you Package if you wish to attend this class']
    redirect_to client_book_path(@client)
  end

  def action_admin_rebook_cancellation_when_prov_expired
    flash_message :warning,
                  ['The purchase has provisionally expired.',
                   'This change may not be possible without first cancelling a booking']
    redirect_to wkclass_path(@booking.wkclass, link_from: params[:booking][:link_from])
  end

  def booking_status_params
    params.require(:booking).permit(:id, :status)
  end
end
