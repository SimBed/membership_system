class Admin::BookingsController < Admin::BaseController
  include BookingsHelper
  skip_before_action :admin_account
  before_action :set_booking, only: :destroy
  before_action :junioradmin_account
  before_action :package_provisionally_expired, only: :create
  # https://stackoverflow.com/questions/49414318/how-to-use-rails-before-action-conditional-for-only-some-actions
  before_action :already_committed, only: :create
  before_action :already_booked_for_class, only: :create
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
      after_successful_create_by_admin
    else
      after_unsuccessful_create_by_admin
    end
  end

  def after_successful_create_by_admin
    @wkclass = @booking.wkclass
    update_purchase_status([@purchase])
    redirect_to wkclass_path(@wkclass, link_from: params[:booking][:link_from], page: params[:booking][:page], show_qualifying_purchases: 'yes')
    flash_message :success, t('.success', name: @booking.client_name)
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

  def already_committed
    set_wkclass_and_purchase
    return unless @purchase.restricted_on?(@wkclass)

    flash_hash = booking_flash_hash.dig(:booking, :daily_limit_met)
    flash_message flash_hash[:colour], (send flash_hash[:message])
    redirect_to wkclass_path(@wkclass)
  end

  # quick successive double-tapping could cause double-booking of class
  # not conceviable for admin through UI
  def already_booked_for_class
    set_wkclass_and_purchase
    return unless @purchase.already_booked_for?(@wkclass)

    flash_hash = booking_flash_hash.dig(:booking, :already_booked)
    flash_message flash_hash[:colour], (send flash_hash[:message])
    redirect_to wkclass_path(@wkclass)
  end

  # longer name with package_ (package_provisionally_expired) so not duplicating method name provisionally_expired of bookings_helper
  def package_provisionally_expired
    # eg class shown as bookable, then purchase becomes provsionally expired due to booking of a different class
    # either on different browser or by admin, then attempting to book the class shown as bookable on first browser should fail
    set_wkclass_and_purchase
    return unless @purchase.provisionally_expired?

    flash_message :warning, t('admin.bookings.action_new_booking_when_prov_expired.admin.warning')
    redirect_to wkclass_path(@wkclass)
  end

  def set_wkclass_and_purchase
    @wkclass = Wkclass.find(params.dig(:booking, :wkclass_id).to_i)
    @purchase = Purchase.find(params.dig(:booking, :purchase_id).to_i)
  end

  def remove_from_waiting_list
    client = @booking.client
    client.waiting_list_for(@wkclass).destroy if client.on_waiting_list_for?(@wkclass)
  end

  # patch requests are no longer handled by this controller but by the booking cancellations controller. Delete requests are handled by this controller though
  # def new_booking?
  #   return true if request.post?

  #   false
  # end
end
