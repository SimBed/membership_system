class Client::BookingsController < Client::BaseController
  include BookingsHelper
  before_action :set_booking_day
  before_action :package_provisionally_expired
  before_action :already_committed
  before_action :already_booked_for_class
  before_action :in_booking_window
  before_action :reached_max_capacity

  def create
    @booking = Booking.new(booking_params)
    if @booking.save
      # needed for after_action callback
      @purchase = @booking.purchase
      handle_freeze
      remove_from_waiting_list
      after_successful_create_by_client
    else
      after_unsuccessful_create_by_client
    end
  end

  def after_successful_create_by_client
    @wkclass = @booking.wkclass
    @wkclass_name = @wkclass.name
    @wkclass_day = @wkclass.day_of_week
    # pass which section the request came from (can only be opengym or group for create) to render the correct turbo_stream to update the correct table opengym/group/my-bookings
    update_purchase_status([@purchase])
    # redirect_to "/client/clients/#{@client.id}/book"
    redirect_to client_book_path(@client, booking_section: params[:booking_section], major_change: @major_change) # pass whether a major change occurred to trigger either a full page reload or just a discrete turbo_frame
    # bookings_helper has booking_flash_hash with a method as a value
    # https://stackoverflow.com/questions/13033830/ruby-function-as-value-of-hash
    # e.g. flash_message :successful, "Booked for Bootcamp on Thursday"
    flash_message booking_flash_hash[:booking][:successful][:colour],
                  (send booking_flash_hash[:booking][:successful][:message], @wkclass_name, @wkclass_day)
  end

  def after_unsuccessful_create_by_client
    redirect_to client_book_path(@client)
    flash_message booking_flash_hash[:booking][:unsuccessful][:colour],
                  (send booking_flash_hash[:booking][:unsuccessful][:message])
  end

  private

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
    redirect_to client_book_path(@client)
  end

  def already_committed
    set_wkclass_and_purchase
    return unless @purchase.restricted_on?(@wkclass)

    flash_hash = booking_flash_hash.dig(:booking, :daily_limit_met)
    flash_message flash_hash[:colour], (send flash_hash[:message])
    redirect_to client_book_path(@client)
  end

  # quick successive double-tapping could cause double-booking of class
  def already_booked_for_class
    set_wkclass_and_purchase
    return unless @purchase.already_booked_for?(@wkclass)

    flash_hash = booking_flash_hash.dig(:booking, :already_booked)
    flash_message flash_hash[:colour], (send flash_hash[:message])
    redirect_to client_book_path(@client)
  end

  def reached_max_capacity
    set_wkclass_and_purchase
    return unless @wkclass.at_capacity?

    action_fully_booked
  end

  def action_fully_booked
    flash_hash = booking_flash_hash[:booking][:fully_booked]
    flash_message flash_hash[:colour], (send flash_hash[:message])
    redirect_to client_book_path(@client)
  end

  def package_provisionally_expired
    # eg class shown as bookable, then purchase becomes provsionally expired due to booking of a different class
    # either on different browser or by admin, then attempting to book the class shown as bookable on first browser should fail
    set_wkclass_and_purchase
    return unless @purchase.provisionally_expired?

    flash_hash = booking_flash_hash[:booking][:provisionally_expired]
    flash_message flash_hash[:colour], (send flash_hash[:message])
    redirect_to client_book_path(@client)
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
