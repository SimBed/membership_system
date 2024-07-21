class Client::BookingsController < Client::BaseController
  include BookingsHelper
  before_action :set_booking_day, only: :create
  before_action :package_provisionally_expired, only: :create
  before_action :already_committed, only: :create
  before_action :already_booked_for_class, only: :create
  before_action :in_booking_window, only: :create
  before_action :reached_max_capacity, only: :create

  def index
    session[:booking_day] = params[:booking_day] || session[:booking_day] || '0'
    @group_wkclasses_show = Wkclass.limited.show_in_bookings_for(@client).order_by_reverse_date
    @open_gym_wkclasses = Wkclass.unlimited.show_in_bookings_for(@client).order_by_reverse_date
    @my_bookings = Wkclass.booked_for(@client).show_in_bookings_for(@client).order_by_reverse_date
    # switching the order round (as below) returns wkclasses with booked bookings not of @client. Couldn't figure this out
    # Wkclass.show_in_bookings_for(@client).booked_for(@client).order_by_reverse_date
    # Wkclass.show_in_bookings_for(c).merge(Wkclass.booked_for(c)).order_by_reverse_date
    @days = (Time.zone.today..Time.zone.today.advance(days: Setting.visibility_window_days_ahead)).to_a
    # Should be done in model
    @group_wkclasses_show_by_day = []
    @opengym_wkclasses_show_by_day = []
    @days.each do |day|
      @group_wkclasses_show_by_day.push(@group_wkclasses_show.on_date(day))
      @opengym_wkclasses_show_by_day.push(@open_gym_wkclasses.on_date(day))
    end
    @no_classes_text_array = (0..@days.length - 1).map do |index|
      Booking.booking_text(@group_wkclasses_show_by_day[index].size, @opengym_wkclasses_show_by_day[index].size, index)
    end
    @other_services = OtherService.all
    # include bookings and wkclass so can find last booked session in PT package without additional query
    @purchases = @client.purchases.not_fully_expired.service_type('group').package.order_by_dop.includes(:freezes, :adjustments, :penalties, bookings: [:wkclass])
    @renewal = Renewal.new(@client)
    params[:booking_section] = nil if params[:major_change] == 'true' # do full page reload if major change
    handle_index_response
  end

  def create
    @booking = Booking.new(booking_params)
    if @booking.save
      # needed for after_action callback
      @purchase = @booking.purchase
      handle_freeze
      remove_from_waiting_list
      after_successful_create
    else
      after_unsuccessful_create
    end
  end

  def after_successful_create
    # pass which section the request came from (can only be opengym or group for create) to render the correct turbo_stream to update the correct table opengym/group/my-bookings
    update_purchase_status([@purchase])
    # redirect_to "/client/clients/#{@client.id}/book"
    redirect_to client_bookings_path(@client, booking_section: params[:booking_section], major_change: @major_change) # pass whether a major change occurred to trigger either a full page reload or just a discrete turbo_frame
    # bookings_helper has booking_flash_hash with a method as a value
    # https://stackoverflow.com/questions/13033830/ruby-function-as-value-of-hash
    # e.g. flash_message :successful, "Booked for Bootcamp on Thursday"
    flash_message booking_flash_hash[:booking][:successful][:colour],
                  (send booking_flash_hash[:booking][:successful][:message], @wkclass.name, @wkclass.day_of_week)
  end

  def after_unsuccessful_create
    redirect_to client_bookings_path(@client)
    flash_message booking_flash_hash[:booking][:unsuccessful][:colour],
                  (send booking_flash_hash[:booking][:unsuccessful][:message])
  end

  private

  def handle_index_response
    respond_to do |format|
      format.html
      case params[:booking_section]
      when 'group'
        format.turbo_stream
      when 'opengym'
        format.turbo_stream { render :opengym }
      when 'my_bookings'
        format.turbo_stream { render :my_bookings }
      else
        format.turbo_stream { render :all_streams }
      end
    end
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

  def booking_params
    params.require(:booking).permit(:wkclass_id, :purchase_id)
  end

  def in_booking_window
    wkclass = Wkclass.find(params.dig(:booking, :wkclass_id).to_i)
    return if wkclass.booking_window.cover?(Time.zone.now)

    flash_hash = booking_flash_hash.dig(:booking, :too_late)
    flash_message flash_hash[:colour], (send flash_hash[:message], false)
    redirect_to client_bookings_path(@client)
  end

  def already_committed
    set_wkclass_and_purchase
    return unless @purchase.restricted_on?(@wkclass)

    flash_hash = booking_flash_hash.dig(:booking, :daily_limit_met)
    flash_message flash_hash[:colour], (send flash_hash[:message])
    redirect_to client_bookings_path(@client)
  end

  # quick successive double-tapping could cause double-booking of class
  def already_booked_for_class
    set_wkclass_and_purchase
    return unless @purchase.already_booked_for?(@wkclass)

    flash_hash = booking_flash_hash.dig(:booking, :already_booked)
    flash_message flash_hash[:colour], (send flash_hash[:message])
    redirect_to client_bookings_path(@client)
  end

  def reached_max_capacity
    set_wkclass_and_purchase
    return unless @wkclass.at_capacity?

    action_fully_booked
  end

  def action_fully_booked
    flash_hash = booking_flash_hash[:booking][:fully_booked]
    flash_message flash_hash[:colour], (send flash_hash[:message])
    redirect_to client_bookings_path(@client)
  end

  def package_provisionally_expired
    # eg class shown as bookable, then purchase becomes provsionally expired due to booking of a different class
    # either on different browser or by admin, then attempting to book the class shown as bookable on first browser should fail
    set_wkclass_and_purchase
    return unless @purchase.provisionally_expired?

    flash_hash = booking_flash_hash[:booking][:provisionally_expired]
    flash_message flash_hash[:colour], (send flash_hash[:message])
    redirect_to client_bookings_path(@client)
  end

  def set_wkclass_and_purchase
    @wkclass = Wkclass.find(params.dig(:booking, :wkclass_id).to_i)
    @purchase = Purchase.find(params.dig(:booking, :purchase_id).to_i)
  end

  # so day on slider shown doesn't revert to default on response
  def set_booking_day
    default_booking_day = 0
    session[:booking_day] = params[:booking_day] || session[:booking_day] || default_booking_day
  end

  def remove_from_waiting_list
    @client.waiting_list_for(@wkclass).destroy if @client.on_waiting_list_for?(@wkclass)
  end
end
