class Admin::AttendancesController < Admin::BaseController
  include AttendancesHelper
  skip_before_action :admin_account
  before_action :fitternity?
  before_action :set_attendance, only: [:update, :destroy]
  before_action :junioradmin_account, only: [:destroy]
  # before_action :junioradmin_or_instructor_account, only: [:new]
  before_action :correct_account_or_junioradmin_or_instructor_account, only: [:create, :update]
  before_action :set_booking_day, only: [:create, :update, :destroy], if: -> { client? }
  before_action :provisionally_expired, only: [:create, :update], unless: -> { fitternity? }
  before_action :modifiable_status, only: [:update]
  # https://stackoverflow.com/questions/49414318/how-to-use-rails-before-action-conditional-for-only-some-actions
  before_action :already_committed, only: [:create, :update], unless: -> { fitternity? }
  # quick successive double-tapping could cause double-booking of class
  before_action :already_booked_for_class, only: [:create]
  before_action :in_booking_window, only: [:create]
  before_action :reached_max_capacity, only: [:create, :update]
  before_action :reached_max_amendments, only: [:update]
  # after_action -> { update_purchase_status([@purchase]) }, only: [:create, :update, :destroy]
  after_action -> { update_purchase_status([@purchase]) }, only: [:update, :destroy]

  def footfall
    Purchase.default_timezone = :utc
    @footfall_for_chart_day = Attendance.joins(:wkclass).attended.group_by_day(:start_time).count
    @footfall_for_chart_week = Attendance.joins(:wkclass).attended.group_by_week(:start_time).count
    @footfall_for_chart_month = Attendance.joins(:wkclass).attended.group_by_month(:start_time).count
    Purchase.default_timezone = :local
  end

  # def new
  #   session[:wkclass_id] = params[:wkclass_id] || session[:wkclass_id]
  #   @attendance = Attendance.new
  #   @wkclass = Wkclass.find(session[:wkclass_id])
  #   # [["Aakash Shah (Fitternity)", "Fitternity 271"],...]
  #   set_new_attendance_dropdown_options
  # end

  def new
    @wkclass = Wkclass.find(params[:wkclass_id])
    @attendance = Attendance.new
    session[:show_qualifying_purchases] = 'yes'
    @qualifying_purchases = Purchase.qualifying_purchases(@wkclass)
  end

  def create
    handle_fitternity and return if fitternity?

    @attendance = Attendance.new(attendance_params)
    if @attendance.save
      # needed for after_action callback
      @purchase = @attendance.purchase
      handle_freeze
      remove_from_waiting_list
      client? ? after_successful_create_by_client : after_successful_create_by_admin
    else
      client? ? after_unsuccessful_create_by_client : after_unsuccessful_create_by_admin
    end
  end

  def handle_fitternity
    purchase_hash = { client_id: @client.id,
                      product_id: 1,
                      price_id: 2,
                      payment: 550,
                      dop: Time.zone.today(),
                      payment_mode: 'Fitternity',
                      fitternity_id: Fitternity.ongoing.first&.id }

    @purchase = Purchase.new(purchase_hash)
    if @purchase.save
      @attendance = Attendance.new(wkclass_id: params[:attendance][:wkclass_id].to_i, purchase_id: @purchase.id)
      if @attendance.save
        after_successful_create_by_admin
      else
        after_unsuccessful_create_by_admin
      end
    else
      after_unsuccessful_create_by_admin
    end
  end

  def after_successful_create_by_client
    @wkclass = @attendance.wkclass
    @wkclass_name = @wkclass.name
    @wkclass_day = @wkclass.day_of_week
    # pass which section the request came from (can only be opengym or group for create) to render the correct turbo_stream to update the correct table opengym/group/my-bookings
    update_purchase_status([@purchase])
    redirect_to client_book_path(@client, booking_section: params[:booking_section], major_change: @major_change) # pass whether a major change occurred to trigger either a full page reload or just a discrete turbo_frame
    # redirect_to "/client/clients/#{@client.id}/book"
    # attendances_helper has booking_flash_hash with a method as a value
    # https://stackoverflow.com/questions/13033830/ruby-function-as-value-of-hash
    flash_message booking_flash_hash[:booking][:successful][:colour],
                  (send booking_flash_hash[:booking][:successful][:message], @wkclass_name, @wkclass_day)
  end

  def after_successful_create_by_admin
    @wkclass = @attendance.wkclass
    update_purchase_status([@purchase])
    redirect_to admin_wkclass_path(@wkclass, link_from: params[:attendance][:link_from], page: params[:attendance][:page], show_qualifying_purchases: 'yes')
    flash_message :success, "#{@attendance.client_name}'s attendance was successfully logged"
  end

  def after_unsuccessful_create_by_client
    redirect_to client_book_path(@client)
    # redirect_to "/client/clients/#{@client.id}/book"
    flash_message booking_flash_hash[:booking][:unsuccessful][:colour],
                  (send booking_flash_hash[:booking][:unsuccessful][:message])
  end

  def after_unsuccessful_create_by_admin
    session[:wkclass_id] = params[:attendance][:wkclass_id] || session[:wkclass_id]
    @attendance = Attendance.new
    @wkclass = Wkclass.find(session[:wkclass_id])
    set_new_attendance_dropdown_options
    render :new, status: :unprocessable_entity
  end

  def update
    @purchase = @attendance.purchase
    @wkclass = @attendance.wkclass
    update_by_client if client?
    if logged_in_as?('junioradmin', 'admin', 'superadmin', 'instructor')
      result = AdminBookingUpdater.new(attendance: @attendance, wkclass: @wkclass, new_status: attendance_status_params[:status]).update
      flash_message(*result.flash_array)
      update_purchase_status([@purchase]) if result.penalty_change?
      if result.success?
        remove_from_waiting_list
        flash_message (notify_waiting_list(@wkclass, triggered_by: 'admin') if ['cancelled early', 'cancelled late'].include? attendance_status_params[:status])
        handle_admin_update_response
      end
    end
  end

  def update_by_client
    basic_data('client')
    action_client_update_too_late && return if @time_of_request == 'too late'

    send "set_data_client_#{@time_of_request}_cancel"
    if @attendance.update(status: @updated_status)
      action_client_update_success

      handle_client_update_response
    else
      flash_client_update_fail
    end
  end

  def destroy
    @wkclass = Wkclass.find(@attendance.wkclass.id)
    @purchase = @attendance.purchase
    @attendance.destroy
    notify_waiting_list(@wkclass, triggered_by: 'admin')
    redirect_to admin_wkclass_path(@wkclass, link_from: params[:link_from])
    flash_message :success, t('.success')
  end

  private

  def fitternity?
    return true if params.dig(:attendance, :purchase_id)&.split&.first == 'Fitternity'

    false
  end

  def set_attendance
    @attendance = Attendance.find(params[:id])
  end

  def set_new_attendance_dropdown_options
    # fitternity now redundant
    # fitternity_options = Client.select {|c| c.fitternity}.reject {|c| c.associated_with?(@wkclass)}.map {|c| ["#{c.name} (Fitternity)", "Fitternity #{c.id}"] }
    @qualifying_purchases = Purchase.qualifying_purchases(@wkclass) #+ fitternity_options
  end

  def handle_freeze
    wkclass_datetime = @attendance.wkclass.start_time
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
      @original_status = @attendance.status
    else # admin
      @client_name = @attendance.client_name
    end
  end

  def set_flash(hash, event)
    flash_message hash.dig(event, :colour), (send hash.dig(event, :message), @wkclass_name, @wkclass_day)
  end

  def attendance_params
    params.require(:attendance).permit(:wkclass_id, :purchase_id)
  end

  def attendance_status_params
    params.require(:attendance).permit(:id, :status)
  end

  # def correct_account_or_junioradmin
  #   @client = if new_booking?
  #               if fitternity?
  #                 # purchase_id key is now not well named as for fitternity its of the form ['Fitternity <client_id>']
  #                 Client.find(params.dig(:attendance, :purchase_id).split.last.to_i)
  #               else
  #                 Purchase.find(params.dig(:attendance, :purchase_id).to_i).client
  #               end
  #             else
  #               # update or destroy
  #               @attendance.client
  #             end

  #   return if current_account?(@client&.account) || logged_in_as?('junioradmin', 'admin', 'superadmin')
  #   flash_message :warning, t('.warning')
  #   # flash[:warning] = 'Forbidden'
  #   redirect_to login_path
  # end

  # make dry
  def correct_account_or_junioradmin_or_instructor_account
    @client = if new_booking?
                if fitternity?
                  # purchase_id key is now not well named as for fitternity its of the form ['Fitternity <client_id>']
                  Client.find(params.dig(:attendance, :purchase_id).split.last.to_i)
                else
                  Purchase.find(params.dig(:attendance, :purchase_id).to_i).client
                end
              else
                # update or destroy
                @attendance.client
              end
    return if current_account?(@client&.account) || logged_in_as?('junioradmin', 'admin', 'superadmin', 'instructor')

    flash_message :warning, t('.warning')
    # flash[:warning] = 'Forbidden'
    redirect_to login_path
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
    @attendance.increment!(:amendment_count)
    if @late_cancellation_by_client
      action_cancelled_late
    elsif @early_cancellation_by_client
      action_cancelled_early
    else # a rebook (and bookings always count)
      @attendance.update(amnesty: false)
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
      @attendance.update(amnesty: true)
    end
  end

  def action_cancelled_early
    @purchase.increment!(:early_cancels)
    @attendance.update(amnesty: true)
  end

  def handle_client_update_response
    set_attendances
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

  def handle_admin_update_response
    set_attendances
    flash_message :success, t('.success', name: @attendance.client_name, status: @attendance.status)
    # redirect_back fallback_location: admin_wkclasses_path
    redirect_to admin_wkclass_path(@attendance.wkclass, link_from: params[:attendance][:link_from], page: params[:attendance][:page])
  end

  def set_attendances
    @physical_attendances = @wkclass.physical_attendances.order_by_status
    @ethereal_attendances_no_amnesty = @wkclass.ethereal_attendances.no_amnesty.order_by_status
    @ethereal_attendances_amnesty = @wkclass.ethereal_attendances.amnesty.order_by_status
  end

  def flash_client_update_fail
    flash_hash = booking_flash_hash[:update][:unsuccessful]
    flash_message flash_hash[:colour], (send flash_hash[:message])
    # flash[flash_hash[:colour]] = send flash_hash[:message]
  end

  def admin_modification?
    return true if logged_in_as?('junioradmin', 'admin', 'superadmin', 'instructor')

    false
  end

  # example1 - browser loads, time passes, client logged as no show,
  # client through browser sends request to cancel booking
  # example2 - non-browser request to update 'attended' to 'cancelled early'
  def modifiable_status
    # client can never modify attended or no show
    return if ['attended', 'no show'].exclude?(@attendance.status) || admin_modification?

    flash_hash = booking_flash_hash[:update][:unmodifiable]
    flash_message flash_hash[:colour], (send flash_hash[:message], @attendance.status)
    # flash[flash_hash[:colour]] =
    #   send flash_hash[:message], @attendance.status
    redirect_to client_book_path(@client)
  end

  def in_booking_window
    wkclass = Wkclass.find(params.dig(:attendance, :wkclass_id).to_i)
    return if (wkclass.booking_window).cover?(Time.zone.now) || admin_modification?

    flash_hash = booking_flash_hash.dig(:booking, :too_late)
    flash_message flash_hash[:colour], (send flash_hash[:message], false)
    # flash_hash[:colour] = send flash_hash[:message], false
    redirect_to client_book_path(@client)
  end

  def already_committed
    set_wkclass_and_booking_type
    # return unless @wkclass.committed_on_same_day?(@client)
    # the old method (above) incorrectly restricted 2 bookings on same day from separate
    # unlimited packages eg group package and nutrition package
    return unless @purchase.restricted_on?(@wkclass)

    flash_hash = booking_flash_hash.dig(@booking_type, :daily_limit_met)
    flash_message flash_hash[:colour], (send flash_hash[:message])
    # flash_hash[:colour] = send flash_hash[:message]
    if client?
      redirect_to client_book_path(@client)
    else # must be admin
      redirect_to admin_wkclass_path(@wkclass)
    end
  end

  def already_booked_for_class
    set_wkclass_and_booking_type
    return unless @purchase.already_booked_for?(@wkclass)

    flash_hash = booking_flash_hash.dig(@booking_type, :already_booked)
    flash_message flash_hash[:colour], (send flash_hash[:message])
    if client?
      redirect_to client_book_path(@client)
    else # must be admin (not conceviable through UI)
      redirect_to admin_wkclass_path(@wkclass)
    end
  end

  def set_wkclass_and_booking_type
    if new_booking?
      @booking_type = :booking
      @rebooking = false
      @wkclass = Wkclass.find(params[:attendance][:wkclass_id].to_i)
      @purchase = Purchase.find(params.dig(:attendance, :purchase_id).to_i)
    else
      @booking_type = :update
      @rebooking = true
      @wkclass = @attendance.wkclass
      @purchase = @attendance.purchase
    end
  end

  def reached_max_capacity
    # admin can override max_capacity
    # note >= comparison not just == as admin may breech maximum capacity,
    # whch should not be a trigger to allow client to further breech it
    return if admin_modification?

    set_wkclass_and_booking_type
    return unless @wkclass.at_capacity?

    action_fully_booked(@booking_type) if new_booking? || ['cancelled early',
                                                           'cancelled late'].include?(@attendance.status)
  end

  def action_fully_booked(booking_type)
    flash_hash = booking_flash_hash[booking_type][:fully_booked]
    flash_message flash_hash[:colour], (send flash_hash[:message], @rebooking)
    # flash[flash_hash[:colour]] = send flash_hash[:message], @rebooking
    redirect_to client_book_path(@client)
  end

  def reached_max_amendments
    return unless client? && @attendance.maxed_out_amendments?

    flash_message booking_flash_hash[:update][:prior_amendments][:colour],
                  (send booking_flash_hash[:update][:prior_amendments][:message])
    # flash[booking_flash_hash[:update][:prior_amendments][:colour]] =
    #   send booking_flash_hash[:update][:prior_amendments][:message]
    redirect_to client_book_path(@client)
  end

  def handle_provisionally_expired_new_booking
    data_items_provisionally_expired(new_booking: true)
    return unless @purchase.provisionally_expired?

    if client?
      flash_message :warning,
                    ['The maximum number of classes has already been booked.',
                     'Renew you Package if you wish to attend this class']
      # flash[:warning] =
      #   ['The maximum number of classes has already been booked.',
      #    'Renew you Package if you wish to attend this class']
      redirect_to client_book_path(@client)
    else
      flash_message :warning, t('admin.attendances.action_new_booking_when_prov_expired.admin.warning')
      # linked_from param is not relevatn as this attempt at booking is not possible throug the UI
      redirect_to admin_wkclass_path(@wkclass)
    end
  end

  def action_client_rebook_cancellation_when_prov_expired
    flash_message :warning,
                  ['The maximum number of classes has already been booked.',
                   'Renew you Package if you wish to attend this class']
    # flash[:warning] =
    #   ['The maximum number of classes has already been booked.',
    #    'Renew you Package if you wish to attend this class']
    redirect_to client_book_path(@client)
  end

  def action_admin_rebook_cancellation_when_prov_expired
    flash_message :warning,
                  ['The purchase has provisionally expired.',
                   'This change may not be possible without first cancelling a booking']
    redirect_to admin_wkclass_path(@attendance.wkclass, link_from: params[:attendance][:link_from])
  end

  def provisionally_expired
    # eg class shown as bookable, then purchase becomes provsionally expired due to booking of a different class
    # either on different browser or by admin, then attempting to book the class shown as bookable on first browser should fail
    if new_booking?
      handle_provisionally_expired_new_booking
    else # update
      data_items_provisionally_expired(new_booking: false)
      if @purchase.provisionally_expired?
        action_client_rebook_cancellation_when_prov_expired if client? && @attendance.status != 'booked'
        # if the change results in an extra class or validity term reduction
        action_admin_rebook_cancellation_when_prov_expired if logged_in_as?('junioradmin', 'admin', 'superadmin') && extra_benefits_after_change?
      end
    end
  end

  def extra_benefits_after_change?
    late_cancels_max = Setting.amnesty_limit[@purchase.product_style][:late_cancels][@purchase.product_type]
    no_shows_max = Setting.amnesty_limit[@purchase.product_style][:no_shows][@purchase.product_type]
    has_late_cancels_amnesty = @purchase.late_cancels < late_cancels_max
    has_no_show_amnesty = @purchase.no_shows < no_shows_max
    amnesty_when_changed = true
    if (params[:attendance][:status] == 'no show' && !has_no_show_amnesty) ||
       (params[:attendance][:status] == 'cancelled late' && !has_late_cancels_amnesty)
      amnesty_when_changed = false
    end
    return true if @attendance.amnesty? && !amnesty_when_changed

    false
  end

  def new_booking?
    return true if request.post?

    false
  end

  def data_items_provisionally_expired(new_booking: true)
    if new_booking
      @purchase = Purchase.find(params.dig(:attendance, :purchase_id).to_i)
      @wkclass = Wkclass.find(params.dig(:attendance, :wkclass_id).to_i)
    else # update
      @purchase = @attendance.purchase
    end
  end

  def late_cancellation_penalty(package_type, penalty: true)
    # no more than one penalty per attendance
    return unless package_type == :unlimited_package && @attendance.penalty.nil?

    if penalty
      Penalty.create({ purchase_id: @purchase.id, attendance_id: @attendance.id, amount: 1,
                       reason: 'late cancellation' })
      update_purchase_status([@purchase])
      @penalty_given = true # for the flash
      # no longer whatsapp as the flash will inform
    end
  end

  def whatsapp_params(message_type)
    { receiver: @purchase.client,
      message_type:,
      variable_contents: { name: @wkclass_name, day: @wkclass_day } }
  end

  def set_period
    default_month = Time.zone.today.beginning_of_month.strftime('%b %Y')
    session[:attendance_period] = params[:attendance_period] || session[:attendance_period] || default_month
    @period = month_period(session[:attendance_period])
    session[:workout_group] = params[:workout_group] || session[:workout_group] || 'All'
  end

  def client?
    logged_in_as?('client')
  end

  def set_booking_day # so day on slider shown doesn't revert to default on response
    default_booking_day = 0
    session[:booking_day] = params[:booking_day] || session[:booking_day] || default_booking_day
  end

  def remove_from_waiting_list
    @client.waiting_list_for(@wkclass).destroy if @client.on_waiting_list_for?(@wkclass)
  end

  # TODO: make dry - repeated in wkclasses controller
  def notify_waiting_list(wkclass, triggered_by: 'admin')
    return if wkclass.in_the_past?

    return if wkclass.at_capacity?

    wkclass.waitings.each do |waiting|
      Whatsapp.new({ receiver: waiting.purchase.client,
                     message_type: 'waiting_list_blast',
                     triggered_by:,
                     variable_contents: { wkclass_name: wkclass.name,
                                          date_time: wkclass.date_time_short } }).manage_messaging
    end
  end
end
