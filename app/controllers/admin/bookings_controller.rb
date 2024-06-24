class Admin::BookingsController < Admin::BaseController
  include BookingsHelper
  skip_before_action :admin_account
  before_action :set_booking, only: :destroy
  before_action :junioradmin_account, only: :destroy
  before_action :correct_account_or_junioradmin_or_instructor_account, only: :create
  before_action :set_booking_day, only: [:create, :destroy], if: -> { client? }
  before_action :package_provisionally_expired, only: :create
  # https://stackoverflow.com/questions/49414318/how-to-use-rails-before-action-conditional-for-only-some-actions
  before_action :already_committed, only: :create
  before_action :already_booked_for_class, only: :create
  before_action :in_booking_window, only: :create
  before_action :reached_max_capacity, only: :create
  after_action -> { update_purchase_status([@purchase]) }, only: :destroy

  def footfall
    Purchase.default_timezone = :utc
    @footfall_for_chart_day = Booking.joins(:wkclass).attended.group_by_day(:start_time).count
    @footfall_for_chart_week = Booking.joins(:wkclass).attended.group_by_week(:start_time).count
    @footfall_for_chart_month = Booking.joins(:wkclass).attended.group_by_month(:start_time).count
    Purchase.default_timezone = :local
  end

  def new
    @wkclass = Wkclass.find(params[:wkclass_id])
    @booking = Booking.new
    session[:show_qualifying_purchases] = 'yes'
    @qualifying_purchases = Purchase.qualifying_purchases(@wkclass)
  end

  def create
    @booking = Booking.new(booking_params)
    if @booking.save
      # needed for after_action callback
      @purchase = @booking.purchase
      handle_freeze
      remove_from_waiting_list
      client? ? after_successful_create_by_client : after_successful_create_by_admin
    else
      client? ? after_unsuccessful_create_by_client : after_unsuccessful_create_by_admin
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

  def after_successful_create_by_admin
    @wkclass = @booking.wkclass
    update_purchase_status([@purchase])
    redirect_to wkclass_path(@wkclass, link_from: params[:booking][:link_from], page: params[:booking][:page], show_qualifying_purchases: 'yes')
    flash_message :success, t('.success', name: @booking.client_name)
  end

  def after_unsuccessful_create_by_client
    redirect_to client_book_path(@client)
    flash_message booking_flash_hash[:booking][:unsuccessful][:colour],
                  (send booking_flash_hash[:booking][:unsuccessful][:message])
  end

  def after_unsuccessful_create_by_admin
    session[:wkclass_id] = params[:booking][:wkclass_id] || session[:wkclass_id]
    @booking = Booking.new
    @wkclass = Wkclass.find(session[:wkclass_id])
    set_new_booking_dropdown_options
    render :new, status: :unprocessable_entity
  end

  def destroy
    @wkclass = Wkclass.find(@booking.wkclass.id)
    @purchase = @booking.purchase
    @booking.destroy
    notify_waiting_list(@wkclass, triggered_by: 'admin')
    redirect_to wkclass_path(@wkclass, link_from: params[:link_from])
    flash_message :success, t('.success')
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def set_new_booking_dropdown_options
    @qualifying_purchases = Purchase.qualifying_purchases(@wkclass)
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

  def booking_status_params
    params.require(:booking).permit(:id, :status)
  end

  # make dry
  def correct_account_or_junioradmin_or_instructor_account
    @client = Purchase.find(params.dig(:booking, :purchase_id).to_i).client
    return if current_account?(@client&.account) || logged_in_as?('junioradmin', 'admin', 'superadmin', 'instructor')

    flash_message :warning, t('.warning')
    redirect_to login_path
  end

  def admin_modification?
    return true if logged_in_as?('junioradmin', 'admin', 'superadmin', 'instructor')

    false
  end

  def in_booking_window
    wkclass = Wkclass.find(params.dig(:booking, :wkclass_id).to_i)
    return if wkclass.booking_window.cover?(Time.zone.now) || admin_modification?

    flash_hash = booking_flash_hash.dig(:booking, :too_late)
    flash_message flash_hash[:colour], (send flash_hash[:message], false)
    redirect_to client_book_path(@client)
  end

  def already_committed
    set_wkclass_and_purchase
    return unless @purchase.restricted_on?(@wkclass)

    flash_hash = booking_flash_hash.dig(:booking, :daily_limit_met)
    flash_message flash_hash[:colour], (send flash_hash[:message])
    if client?
      redirect_to client_book_path(@client)
    else # must be admin
      redirect_to wkclass_path(@wkclass)
    end
  end

  # quick successive double-tapping could cause double-booking of class
  def already_booked_for_class
    set_wkclass_and_purchase
    return unless @purchase.already_booked_for?(@wkclass)

    flash_hash = booking_flash_hash.dig(:booking, :already_booked)
    flash_message flash_hash[:colour], (send flash_hash[:message])
    if client?
      redirect_to client_book_path(@client)
    else # must be admin (not conceviable through UI)
      redirect_to wkclass_path(@wkclass)
    end
  end

  def reached_max_capacity
    # admin can override max_capacity
    # note >= comparison not just == as admin may breech maximum capacity,
    # whch should not be a trigger to allow client to further breech it
    return if admin_modification?

    set_wkclass_and_purchase
    return unless @wkclass.at_capacity?

    action_fully_booked
  end

  def action_fully_booked
    flash_hash = booking_flash_hash[:booking][:fully_booked]
    flash_message flash_hash[:colour], (send flash_hash[:message])
    redirect_to client_book_path(@client)
  end

  # longer name with package_ (package_provisionally_expired) so not duplicating method name provisionally_expired of bookings_helper
  def package_provisionally_expired
    # eg class shown as bookable, then purchase becomes provsionally expired due to booking of a different class
    # either on different browser or by admin, then attempting to book the class shown as bookable on first browser should fail
    set_wkclass_and_purchase
    return unless @purchase.provisionally_expired?

    if client?
      flash_hash = booking_flash_hash[:booking][:provisionally_expired]
      flash_message flash_hash[:colour], (send flash_hash[:message])
      redirect_to client_book_path(@client)
    else
      flash_message :warning, t('admin.bookings.action_new_booking_when_prov_expired.admin.warning')
      redirect_to wkclass_path(@wkclass)
    end
  end

  def set_wkclass_and_purchase
    @wkclass = Wkclass.find(params.dig(:booking, :wkclass_id).to_i)
    @purchase = Purchase.find(params.dig(:booking, :purchase_id).to_i)
  end

  def client?
    logged_in_as?('client')
  end

  # so day on slider shown doesn't revert to default on response
  def set_booking_day
    default_booking_day = 0
    session[:booking_day] = params[:booking_day] || session[:booking_day] || default_booking_day
  end

  def remove_from_waiting_list
    @client.waiting_list_for(@wkclass).destroy if @client.on_waiting_list_for?(@wkclass)
  end

  # patch requests are no longer handled by this controller but by the booking cancellations controller. Delete requests are handled by this controller though
  # def new_booking?
  #   return true if request.post?

  #   false
  # end
end
