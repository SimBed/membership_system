class Admin::AttendancesController < Admin::BaseController
  include AttendancesHelper
  skip_before_action :admin_account
  before_action :set_attendance, only: [:update, :destroy]
  before_action :junioradmin_account, only: [:new, :destroy, :index]
  before_action :correct_account_or_junioradmin, only: [:create, :update, :destroy]
  before_action :provisionally_expired, only: [:create, :update]
  before_action :modifiable_status, only: [:update]
  before_action :already_committed, only: [:create, :update]
  before_action :in_booking_window, only: [:create]
  before_action :reached_max_capacity, only: [:create, :update]
  before_action :reached_max_amendments, only: [:update]
  after_action -> { update_purchase_status([@purchase]) }, only: [:create, :update, :destroy]

  def new
    session[:wkclass_id] = params[:wkclass_id] || session[:wkclass_id]
    @attendance = Attendance.new
    @wkclass = Wkclass.find(session[:wkclass_id])
    @qualifying_purchases = qualifying_purchases
  end

  def create
    @attendance = Attendance.new(attendance_params)
    if @attendance.save
      # needed for after_action callback
      @purchase = @attendance.purchase
      handle_freeze
      logged_in_as?('client') ? after_successful_create_by_client : after_successful_create_by_admin
    else
      logged_in_as?('client') ? after_unsuccessful_create_by_client : after_unsuccessful_create_by_admin
    end
  end

  def after_successful_create_by_client
    @wkclass = @attendance.wkclass
    @wkclass_name = @wkclass.name
    @wkclass_day = @wkclass.day_of_week
    redirect_to client_book_path(@client)
    # redirect_to "/client/clients/#{@client.id}/book"
    # attendances_helper has booking_flash_hash with a method as a value
    # https://stackoverflow.com/questions/13033830/ruby-function-as-value-of-hash
    flash_message booking_flash_hash[:booking][:successful][:colour],
                  (send booking_flash_hash[:booking][:successful][:message], @wkclass_name, @wkclass_day)
    # flash[booking_flash_hash[:booking][:successful][:colour]] =
    #   send booking_flash_hash[:booking][:successful][:message], @wkclass_name, @wkclass_day
  end

  def after_successful_create_by_admin
    @client_name = @attendance.purchase.client.name
    redirect_to admin_wkclass_path(@attendance.wkclass, no_scroll: true)
    flash_message :success, "#{@client_name}'s attendance was successfully logged"
    # flash[:success] = "#{@client_name}'s attendance was successfully logged"
    # @wkclass = Wkclass.find(params[:attendance][:wkclass_id])
  end

  def after_unsuccessful_create_by_client
    redirect_to client_book_path(@client)
    # redirect_to "/client/clients/#{@client.id}/book"
    flash_message booking_flash_hash[:booking][:unsuccessful][:colour],
                  (send booking_flash_hash[:booking][:unsuccessful][:message])
    # flash[booking_flash_hash[:booking][:unsuccessful][:colour]] =
    #   send booking_flash_hash[:booking][:unsuccessful][:message]
  end

  def after_unsuccessful_create_by_admin
    session[:wkclass_id] = params[:attendance][:wkclass_id] || session[:wkclass_id]
    @attendance = Attendance.new
    @wkclass = Wkclass.find(session[:wkclass_id])
    @qualifying_purchases = qualifying_purchases
    render :new, status: :unprocessable_entity
  end

  def update
    @purchase = @attendance.purchase
    @wkclass = Wkclass.find(@attendance.wkclass.id)
    update_by_client if logged_in_as?('client')
    update_by_admin if logged_in_as?('junioradmin', 'admin', 'superadmin')
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

  def update_by_admin
    basic_data('admin')
    if @attendance.update(attendance_status_params)
      action_admin_update_success
      handle_admin_update_response
    else
      flash_message :warning, t('.warning')
      # flash[:warning] = t('.warning')
    end
  end

  def destroy
    @wkclass = Wkclass.find(@attendance.wkclass.id)
    @purchase = @attendance.purchase
    @attendance.destroy
    redirect_to admin_wkclass_path(@wkclass, no_scroll: true)
    flash_message :success, t('.success')
    # flash[:success] = t('.success')
  end

  # index of attendances not used - available by explicit url but not by navigation link
  def index
    set_period
    @attendances = Attendance.by_workout_group(session[:workout_group], @period)
    # @attendances.sort_by { |a| [a.wkclass.start_time, a.purchase.name] }.reverse!
    @revenue = @attendances.map(&:revenue).inject(0, :+)
    @months = months_logged
    @workout_groups = ['All'] + WorkoutGroup.all.map { |wg| [wg.name.to_s] }
  end

  private

  # e.g. [["Aparna Shah 9C:5W Feb 12", 1], ["Aryan Agarwal UC:3M Jan 31", 2, {class: "close_to_expiry"}], ...]
  def qualifying_purchases
    Purchase.qualifying_for(@wkclass).map do |p|
      close_to_expiry = 'close_to_expiry' if p.close_to_expiry? && !p.dropin?
      ["#{p.client.first_name} #{p.client.last_name} #{p.name} #{p.dop.strftime('%b %d')}", p.id,
       { class: close_to_expiry }]
    end
  end

  def set_attendance
    @attendance = Attendance.find(params[:id])
  end

  def handle_freeze
    wkclass_date = @attendance.wkclass.start_time.to_date
    # unlikley to be more than 1, but you never know
    applicable_freezes = @purchase.freezes_cover(wkclass_date)
    return if applicable_freezes.empty?

    applicable_freezes.each do |f|
      # wish to bypass validation, else would just use update method
      f.end_date = wkclass_date.advance(days: -1)
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
      @client_name = @attendance.purchase.client.name
    end
  end

  def set_flash(hash, event)
    flash_message hash.dig(event, :colour), (send hash.dig(event, :message), @wkclass_name, @wkclass_day)
    # flash[hash.dig(event, :colour)] = send hash.dig(event, :message), @wkclass_name, @wkclass_day
  end

  def attendance_params
    params.require(:attendance).permit(:wkclass_id, :purchase_id)
  end

  def attendance_status_params
    params.require(:attendance).permit(:id, :status)
  end

  def correct_account_or_junioradmin
    @client = if new_booking?
                Purchase.find(params.dig(:attendance, :purchase_id).to_i).client
              else
                # update or destroy
                @attendance.client
              end

    return if current_account?(@client&.account) || logged_in_as?('junioradmin', 'admin', 'superadmin')

    flash_message flash[:warning], t('.warning')
    # flash[:warning] = t('.warning')
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
  end

  def action_admin_update_success
    # if the amendment count is not incremented when admin does it, risk getting out of sync if client does one,
    # then admin does the next such that a) 3rd amendment is breeched and
    # b) client stranded with a booked class she cant cancel herself
    @attendance.increment!(:amendment_count)
    attendance_status = attendance_status_params[:status]
    if ['cancelled early', 'cancelled late', 'no show'].include? attendance_status
      send "action_#{attendance_status.split.join('_')}"
    else # attended or a rebook (which always count)
      @attendance.update(amnesty: false)
      handle_freeze
    end
  end

  def action_cancelled_late
    @purchase.increment!(:late_cancels)
    late_cancels_max = amnesty_limit[:cancel_late][@purchase.product_type]
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

  def action_no_show
    @purchase.increment!(:no_shows)
    no_shows_max = amnesty_limit[:no_show][@purchase.product_type]
    if @purchase.reload.no_shows > no_shows_max
      no_show_penalty @purchase.product_type, penalty: true
    else
      no_show_penalty @purchase.product_type, penalty: false
      @attendance.update(amnesty: true)
    end
  end

  def handle_client_update_response
    set_attendances
    respond_to do |format|
      format.html do
        flash_client_update_success
        redirect_to client_book_path(@client)
      end
      format.js do
        # not currently used
        flash.now[:success] = "Booking for #{@wkclass_name} on #{@wkclass_day} updated to '#{@updated_status}'"
        render 'admin/wkclasses/update_attendance.js.erb'
      end
    end
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
    respond_to do |format|
      format.html do
        flash_message :success, t('.success')
        # flash[:success] = t('.success')
        redirect_back fallback_location: admin_wkclasses_path
      end
      format.js do
        flash.now[:success] = "#{@client_name}'s booking was successfully updated to  #{@attendance.status}"
        render 'admin/wkclasses/update_attendance.js.erb'
      end
    end
  end

  def set_attendances
    @attendances = @wkclass.attendances.no_amnesty.order_by_status
    @amnesties = @wkclass.attendances.amnesty.order_by_status
  end

  def flash_client_update_fail
    flash_hash = booking_flash_hash[:update][:unsuccessful]
    flash_message flash_hash[:colour], (send flash_hash[:message])
    # flash[flash_hash[:colour]] = send flash_hash[:message]
  end

  def admin_modification?
    return true if logged_in_as?('junioradmin', 'admin', 'superadmin')

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
    return unless @wkclass.committed_on_same_day?(@client)

    flash_hash = booking_flash_hash.dig(@booking_type, :daily_limit_met)
    flash_message flash_hash[:colour], (send flash_hash[:message])
    # flash_hash[:colour] = send flash_hash[:message]
    if logged_in_as?('client')
      redirect_to client_book_path(@client)
    else # must be admin
      redirect_to admin_wkclass_path(@wkclass, no_scroll: true)
    end
  end

  def set_wkclass_and_booking_type
    if new_booking?
      @booking_type = :booking
      @rebooking = false
      @wkclass = Wkclass.find(params[:attendance][:wkclass_id].to_i)
    else
      @booking_type = :update
      @rebooking = true
      @wkclass = @attendance.wkclass
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
    return unless logged_in_as?('client') && @attendance.maxed_out_amendments?

    flash_message booking_flash_hash[:update][:prior_amendments][:colour], (send booking_flash_hash[:update][:prior_amendments][:message])
    # flash[booking_flash_hash[:update][:prior_amendments][:colour]] =
    #   send booking_flash_hash[:update][:prior_amendments][:message]
    redirect_to client_book_path(@client)
  end

  def handle_provisionally_expired_new_booking
    data_items_provisionally_expired(new_booking: true)
    return unless @purchase.provisionally_expired?

    if logged_in_as?('client')
      flash_message :warning, ['The maximum number of classes has already been booked.', 'Renew you Package if you wish to attend this class']
      # flash[:warning] =
      #   ['The maximum number of classes has already been booked.',
      #    'Renew you Package if you wish to attend this class']
      redirect_to client_book_path(@client)
    else
      flash_message :warning, t('admin.attendances.action_new_booking_when_prov_expired.admin.warning')
      # flash[:warning] = I18n.t 'admin.attendances.action_new_booking_when_prov_expired.admin.warning'
      redirect_to admin_wkclass_path(@wkclass, no_scroll: true)
    end
  end

  def action_client_rebook_cancellation_when_prov_expired
    flash_message :warning, ['The maximum number of classes has already been booked.', 'Renew you Package if you wish to attend this class']
    # flash[:warning] =
    #   ['The maximum number of classes has already been booked.',
    #    'Renew you Package if you wish to attend this class']
    redirect_to client_book_path(@client)
  end

  def action_admin_rebook_cancellation_when_prov_expired
    flash_message :warning, ['The purchase has provisionally expired.', 'This change may not be possible without first cancelling a booking']
    # flash[:warning] =
    #   ['The purchase has provisionally expired.',
    #    'This change may not be possible without first cancelling a booking']
    redirect_to admin_wkclass_path(@attendance.wkclass, no_scroll: true)
  end

  def provisionally_expired
    # eg class shown as bookable, then purchase becomes provsionally expired due to booking of a different class
    # either on different browser or by admin, then attempting to book the class shown as bookable on first browser should fail
    if new_booking?
      handle_provisionally_expired_new_booking
    else # update
      data_items_provisionally_expired(new_booking: false)
      if @purchase.provisionally_expired?
        action_client_rebook_cancellation_when_prov_expired if logged_in_as?('client') && @attendance.status != 'booked'
        # if the change results in an extra class or validity term reduction
        if logged_in_as?('junioradmin', 'admin', 'superadmin') && extra_benefits_after_change?
          action_admin_rebook_cancellation_when_prov_expired
        end
      end
    end
  end

  def extra_benefits_after_change?
    late_cancels_max = amnesty_limit[:cancel_late][@purchase.product_type]
    no_shows_max = amnesty_limit[:no_show][@purchase.product_type]
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

  # redundant?
  # booked and attended already count in all circumstances so changing them wont risk providing excess benefit
  # [this is true in context of fixed classes, not quite true for unlimited.
  # Deal with eg unlimited attended to no amnesty no show later]
  # return if %w[booked attended].include?(@attendance.status)

  def late_cancellation_penalty(package_type, penalty: true)
    # return if Rails.env.production?
    # no more than one penalty per attendance
    return unless package_type == :unlimited_package && @attendance.penalty.nil?

    if penalty
      Penalty.create({ purchase_id: @purchase.id, attendance_id: @attendance.id, amount: 1,
                       reason: 'late cancellation' })
      update_purchase_status([@purchase])
      @penalty_given = true # for the flash
      flash_message *Whatsapp.new(whatsapp_params('late_cancel_penalty')).manage_messaging
      # manage_messaging 'late_cancel_penalty'
    else
      flash_message *Whatsapp.new(whatsapp_params('late_cancel_no_penalty')).manage_messaging
      # manage_messaging 'late_cancel_no_penalty'
    end
  end

  def no_show_penalty(package_type, penalty: true)
    # return if Rails.env.production?
    return unless package_type == :unlimited_package && @attendance.penalty.nil?

    if penalty
      Penalty.create({ purchase_id: @purchase.id, attendance_id: @attendance.id, amount: 2, reason: 'no show' })
      update_purchase_status([@purchase])
      flash_message *Whatsapp.new(whatsapp_params('no_show_penalty')).manage_messaging
      # manage_messaging 'no_show_penalty'
    else
      flash_message *Whatsapp.new(whatsapp_params('no_show_no_penalty')).manage_messaging
      # manage_messaging 'no_show_no_penalty'
    end
  end

  def whatsapp_params(message_type)
    { receiver: @purchase.client,
      message_type: message_type,
      variable_contents: { name: @wkclass_name, day: @wkclass_day } }
  end

  # def manage_messaging(message_type)
  #   recipient_number = @purchase.client.whatsapp_messaging_number
  #   if recipient_number.nil?
  #     flash_message :warning, "Client has no contact number. #{message_type} message not sent"
  #   else
  #     return unless white_list_whatsapp_receivers
  #
  #     send_message recipient_number, message_type
  #     flash_message :warning, "#{message_type} message sent to #{recipient_number}"
  #   end
  # end
  #
  # def send_message(to, message_type)
  #   return unless white_list_whatsapp_receivers
  #
  #   whatsapp_params = { to: to,
  #                       message_type: message_type,
  #                       variable_contents: { name: @wkclass.name, day: @wkclass.day_of_week } }
  #   Whatsapp.new(whatsapp_params).send_whatsapp
  # end

  def set_period
    default_month = Time.zone.today.beginning_of_month.strftime('%b %Y')
    session[:attendance_period] = params[:attendance_period] || session[:attendance_period] || default_month
    @period = month_period(session[:attendance_period])
    session[:workout_group] = params[:workout_group] || session[:workout_group] || 'All'
  end
end
