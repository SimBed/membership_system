class Admin::AttendancesController < Admin::BaseController
  include AttendancesHelper
  skip_before_action :admin_account
  before_action :set_attendance, only: [:update, :destroy]
  before_action :junioradmin_account, only: [:new, :destroy, :index]
  before_action :correct_account_or_junioradmin, only: [:create, :update, :destroy]
  before_action :provisionally_expired, only: [:create, :update]
  before_action :modifiable_status, only: [:update]
  before_action :already_booked_or_attended, only: [:create, :update]
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
      if logged_in_as?('client')
        after_successful_create_by_client
      else
        after_successful_create_by_admin
      end
    elsif logged_in_as?('client')
      after_unsuccessful_create_by_client
    else
      after_unsuccessful_create_by_admin
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
    flash[booking_flash_hash[:booking][:successful][:colour]] =
      send booking_flash_hash[:booking][:successful][:message], @wkclass_name, @wkclass_day
  end

  def after_successful_create_by_admin
    @client_name = @attendance.purchase.client.name
    redirect_to admin_wkclass_path(@attendance.wkclass, no_scroll: true)
    flash[:success] = "#{@client_name}'s attendance was successfully logged"
    # @wkclass = Wkclass.find(params[:attendance][:wkclass_id])
  end

  def after_unsuccessful_create_by_client
    redirect_to client_book_path(@client)
    # redirect_to "/client/clients/#{@client.id}/book"
    flash[booking_flash_hash[:booking][:unsuccessful][:colour]] =
      send booking_flash_hash[:booking][:unsuccessful][:message]
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
    @wkclass_name = @wkclass.name
    @wkclass_day = @wkclass.day_of_week
    @time_of_request = time_of_request
    @original_status = @attendance.status
    case @time_of_request
    when 'early'
      if @original_status == 'booked'
        @updated_status = 'cancelled early'
        early_cancellation_by_client = true
      else
        @updated_status = 'booked'
      end
    when 'late'
      if @original_status == 'booked'
        @updated_status = 'cancelled late'
        # late cancellations sometimes count
        late_cancellation_by_client = true
      else
        @updated_status = 'booked'
      end
    when 'too late'
      flash[booking_flash_hash[:update][:too_late][:colour]] =
        send booking_flash_hash[:update][:too_late][:message], true, @wkclass_name
      redirect_to client_book_path(@client)
      return
    end
    if @attendance.update(status: @updated_status)
      @attendance.increment!(:amendment_count)
      if late_cancellation_by_client
        @purchase.increment!(:late_cancels)
        late_cancels_max = amnesty_limit[:cancel_late][@purchase.product_type]
        if @purchase.reload.late_cancels > late_cancels_max
          late_cancellation_penalty(@purchase.product_type)
          # amnesty remains false from earlier booking
        else
          @attendance.update(amnesty: true)
        end
      elsif early_cancellation_by_client
        @purchase.increment!(:early_cancels)
        @attendance.update(amnesty: true)
      else # a rebook (and bookings always count)
        @attendance.update(amnesty: false)
      end
      respond_to do |format|
        format.html do
          flash_for_successful_client_update
          redirect_to client_book_path(@client)
        end
        format.js do
          # not currently used
          flash.now[:success] = "Booking for #{@wkclass_name} on #{@wkclass_day} updated to '#{@updated_status}'"
          render 'admin/wkclasses/update_attendance.js.erb'
        end
      end
    else
      flash[booking_flash_hash[:update][:unsuccessful][:colour]] =
        send booking_flash_hash[:update][:unsuccessful][:message]
    end
  end

  # https://stackoverflow.com/questions/49952991/add-a-line-break-in-a-flash-notice-rails-controller
  # adding newline to flash surprisingly awkward. Adapted application.html.erb per 'dirty' suggestion.
  def flash_for_successful_client_update
    if @original_status == 'booked'
      if @time_of_request == 'early'
        flash[booking_flash_hash[:update][:cancel_early][:colour]] =
          send booking_flash_hash[:update][:cancel_early][:message], @wkclass_name, @wkclass_day
      else # late
        cancel_late_type = @penalty_given ? :cancel_late_no_amnesty : :cancel_late_amnesty
        flash[booking_flash_hash[:update][cancel_late_type][:colour]] =
          send booking_flash_hash[:update][cancel_late_type][:message], @wkclass_name, @wkclass_day
      end
    else # cancelled to booked
      flash[booking_flash_hash[:update][:successful][:colour]] =
        send booking_flash_hash[:update][:successful][:message], @wkclass_name, @wkclass_day
    end
  end

  def update_by_admin
    @client_name = @attendance.purchase.client.name
    if @attendance.update(attendance_status_params)
      # if the amendment count is not incremented when admin does it, risk getting out of sync if client does one,
      # then admin does the next such that a) 3rd amendment is breeched and
      # b) client stranded with a booked class she cant cancel herself
      @attendance.increment!(:amendment_count)
      attendance_status = attendance_status_params[:status]
      case attendance_status
      when 'cancelled late'
        @purchase.increment!(:late_cancels)
        late_cancels_max = amnesty_limit[:cancel_late][@purchase.product_type]
        if @purchase.reload.late_cancels > late_cancels_max
          late_cancellation_penalty(@purchase.product_type)
        else
          @attendance.update(amnesty: true)
        end
      when 'cancelled early'
        @purchase.increment!(:early_cancels)
        @attendance.update(amnesty: true)
      when 'no show'
        @purchase.increment!(:no_shows)
        no_shows_max = amnesty_limit[:no_show][@purchase.product_type]
        if @purchase.reload.no_shows > no_shows_max
          no_show_penalty(@purchase.product_type)
        else
          @attendance.update(amnesty: true)
        end
      else # attended or a rebook (which always count)
        @attendance.update(amnesty: false)
      end
      respond_to do |format|
        format.html do
          flash[:success] = 'Attendance was successfully updated'
          redirect_back fallback_location: admin_wkclasses_path
        end
        format.js do
          flash.now[:success] = "#{@client_name}'s attendance was successfully updated to  #{@attendance.status}"
          render 'admin/wkclasses/update_attendance.js.erb'
        end
      end
    else
      flash[:warning] = 'Attendance was not updated'
    end
  end

  def destroy
    @wkclass = Wkclass.find(@attendance.wkclass.id)
    @purchase = @attendance.purchase
    @attendance.destroy
    redirect_to admin_wkclass_path(@wkclass, no_scroll: true)
    flash[:success] = 'Attendance was successfully removed'
  end

  # index of attendances not used - available by explicit url but not by navigation link
  def index
    session[:attendance_period] =
      params[:attendance_period] || session[:attendance_period] || Time.zone.today.beginning_of_month.strftime('%b %Y')
    session[:workout_group] = params[:workout_group] || session[:workout_group] || 'All'
    start_date = Date.parse(session[:attendance_period])
    end_date = Date.parse(session[:attendance_period]).end_of_month.end_of_day
    @attendances = Attendance.by_workout_group(session[:workout_group], start_date, end_date)
    @attendances.sort_by { |a| [a.wkclass.start_time, a.purchase.name] }.reverse!
    @revenue = @attendances.map(&:revenue).inject(0, :+)
    # prepare items for the revenue date select
    # months_logged method defined in application helper
    @months = months_logged
    # prepare items for the workout group select
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

  def attendance_params
    params.require(:attendance).permit(:wkclass_id, :purchase_id)
  end

  def attendance_status_params
    params.require(:attendance).permit(:id, :status)
  end

  def correct_account_or_junioradmin
    @client = if params.key?(:attendance) && params[:attendance].key?(:purchase_id)
                # !params.dig(:attendance, :purchase_id).nil?
                # if create
                Client.find(Purchase.find(params[:attendance][:purchase_id].to_i).client.id)
              else
                # if update or destroy
                @attendance.client
              end
    return if current_account?(@client&.account) || logged_in_as?('junioradmin', 'admin', 'superadmin')

    flash[:warning] = 'Forbidden'
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

    flash[booking_flash_hash[:update][:unmodifiable][:colour]] =
      send booking_flash_hash[:update][:unmodifiable][:message], @attendance.status
    redirect_to client_book_path(@client)
  end

  def in_booking_window
    wkclass = Wkclass.find(params[:attendance][:wkclass_id].to_i)
    days_before = 1
    window_start = wkclass.start_time.ago(days_before.days).beginning_of_day
    window_end = wkclass.start_time - 5.minutes
    return if (window_start..window_end).cover?(Time.zone.now) || admin_modification?

    flash[booking_flash_hash[:booking][:too_late][:colour]] =
      send booking_flash_hash[:booking][:too_late][:message], false
    redirect_to client_book_path(@client)
  end

  def already_booked_or_attended
    # booking_type = params.has_key?(:attendance) && params[:attendance].has_key?(:wkclass_id) ? :booking: :update
    booking_type = request.post? ? :booking : :update
    @wkclass = booking_type == :booking ? Wkclass.find(params[:attendance][:wkclass_id].to_i) : @attendance.wkclass
    return unless @wkclass.booked_or_attended_on_same_day?(@client)

    flash[booking_flash_hash[booking_type][:daily_limit_met][:colour]] =
      send booking_flash_hash[booking_type][:daily_limit_met][:message]
    if logged_in_as?('client')
      redirect_to client_book_path(@client)
    else # must be admin
      redirect_to admin_wkclass_path(@wkclass, no_scroll: true)
    end
  end

  def reached_max_capacity
    # admin can override max_capacity
    # note >= comparison not just == as admin may breech maximum capacity,
    # whch should not be a trigger to allow client to further breech it

    return unless logged_in_as?('client')

    if request.post?
      @wkclass = Wkclass.find(params[:attendance][:wkclass_id].to_i)
      if @wkclass.attendances.no_amnesty.count >= @wkclass.max_capacity
        flash[booking_flash_hash[:booking][:fully_booked][:colour]] =
          send booking_flash_hash[:booking][:fully_booked][:message], false
        redirect_to client_book_path(@client)
      end
    elsif @wkclass.attendances.no_amnesty.count >= @wkclass.max_capacity &&
          ['cancelled early', 'cancelled late'].include?(@attendance.status)
      flash[booking_flash_hash[:update][:fully_booked][:colour]] =
        send booking_flash_hash[:update][:fully_booked][:message], true
      redirect_to client_book_path(@client)
    end
  end

  def reached_max_amendments
    return unless logged_in_as?('client') && (@attendance.amendment_count >= settings[:amendment_count])

    flash[booking_flash_hash[:update][:prior_amendments][:colour]] =
      send booking_flash_hash[:update][:prior_amendments][:message]
    redirect_to client_book_path(@client)
  end

  def provisionally_expired
    # eg class shown as bookable, then purchase becomes provsionally expired due to booking of a different class
    # either on different browser or by admin, attempting to book the class shown as bookable on first browser should fail
    if request.post?
      purchase = Purchase.find(params[:attendance][:purchase_id].to_i)
      if ['provisionally expired'].include?(purchase.status)
        if logged_in_as?('client')
          flash[:warning] =
            ['The maximum number of classes has already been booked.',
             'Renew you Package if you wish to attend this class']
          redirect_to client_book_path(@client)
        else
          flash[:warning] = 'The maximum number of classes has already been booked'
          redirect_to admin_wkclass_path(@wkclass, no_scroll: true)
        end
      end
    else # patch
      purchase = @attendance.purchase
      if ['provisionally expired'].include?(purchase.status)
        if logged_in_as?('client')
          if @attendance.status != 'booked' # ie trying to change cancelled to booked
            flash[:warning] =
              ['The maximum number of classes has already been booked.',
               'Renew you Package if you wish to attend this class']
            redirect_to client_book_path(@client)
          end
        else # admin
          late_cancels_max = amnesty_limit[:cancel_late][purchase.product_type]
          no_shows_max = amnesty_limit[:no_show][purchase.product_type]
          has_late_cancels_amnesty = purchase.late_cancels < late_cancels_max
          has_no_show_amnesty = purchase.no_shows < no_shows_max
          change_results_in_no_amnesty = false
          if (params[:attendance][:status] == 'no show' &&
            !has_no_show_amnesty) ||
             (params[:attendance][:status] == 'cancelled late' &&
            !has_late_cancels_amnesty)
            change_results_in_no_amnesty = true
          end
          # if the change results in an extra class or validity term reduction
          # booked and return already count in all circumstances so changing them wont risk providing excess benefit
          # [this is true in context of fixed classes, not quite true for unlimited.
          # Deal with eg unlimited attended to no amnesty no show later]
          return if %w[booked attended].include?(@attendance.status)

          if @attendance.amnesty? && change_results_in_no_amnesty
            flash[:warning] =
              ['The purchase has provisionally expired.',
               'This change may not be possible without first cancelling a booking']
            redirect_to admin_wkclass_path(@attendance.wkclass, no_scroll: true)
          end
        end
      end
    end
  end

  def late_cancellation_penalty(package_type)
    return if Rails.env.production?
    # no more than one penalty per attendance
    return unless package_type == :unlimited_package && @attendance.penalty.nil?

    Penalty.create({ purchase_id: @purchase.id, attendance_id: @attendance.id, amount: 1,
                     reason: 'late cancellation' })
    @penalty_given = true # for the flash
    update_purchase_status([@purchase])
  end

  def no_show_penalty(package_type)
    return if Rails.env.production?
    return unless package_type == :unlimited_package && @attendance.penalty.nil?

    Penalty.create({ purchase_id: @purchase.id, attendance_id: @attendance.id, amount: 2, reason: 'no show' })
    update_purchase_status([@purchase])
  end
end
