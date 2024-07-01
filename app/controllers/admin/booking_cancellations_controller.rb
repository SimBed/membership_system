class Admin::BookingCancellationsController < Admin::BaseController
  include BookingsHelper
  skip_before_action :admin_account
  before_action :set_booking
  before_action :junioradmin_account
  before_action :provisionally_expired
  before_action :already_committed
  after_action -> { update_purchase_status([@purchase]) }

  def update
    @purchase = @booking.purchase
    @wkclass = @booking.wkclass
    result = AdminBookingUpdater.new(booking: @booking, wkclass: @wkclass, new_status: booking_status_params[:status]).update
    flash_message(*result.flash_array)
    update_purchase_status([@purchase]) if result.penalty_change?
    return unless result.success?

    remove_from_waiting_list
    notify_waiting_list(@wkclass, triggered_by: 'admin') if ['cancelled early', 'cancelled late'].include? booking_status_params[:status]
    handle_admin_update_response
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

  def remove_from_waiting_list
    client = @booking.client
    client.waiting_list_for(@wkclass).destroy if client.on_waiting_list_for?(@wkclass)
  end

  def handle_admin_update_response
    set_attendances
    flash_message :success, t('.success', name: @booking.client_name, status: @booking.status)
    redirect_to wkclass_path(@booking.wkclass, link_from: params[:booking][:link_from], page: params[:booking][:page])
  end

  def set_attendances
    @cancelled_bookings_no_amnesty = @wkclass.cancelled_bookings.no_amnesty.order_by_status
    @cancelled_bookings_amnesty = @wkclass.cancelled_bookings.amnesty.order_by_status
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

  def set_flash(hash, event)
    flash_message hash.dig(event, :colour), (send hash.dig(event, :message), @wkclass_name, @wkclass_day)
  end

  def provisionally_expired
    # eg class shown as bookable, then purchase becomes provsionally expired due to booking of a different class
    # either on different browser or by admin, then attempting to book the class shown as bookable on first browser should fail
    @purchase = @booking.purchase
    if @purchase.provisionally_expired?
      # if the change results in an extra class or validity term reduction
      action_admin_rebook_cancellation_when_prov_expired if extra_benefits_after_change?
    end
  end

  def already_committed
    set_wkclass_and_booking_type
    return unless @purchase.restricted_on?(@wkclass)

    flash_hash = booking_flash_hash.dig(@booking_type, :daily_limit_met)
    flash_message flash_hash[:colour], (send flash_hash[:message])
    redirect_to wkclass_path(@wkclass)
  end

  def set_wkclass_and_booking_type
    @booking_type = :update
    @rebooking = true
    @wkclass = @booking.wkclass
    @purchase = @booking.purchase
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