class Admin::WkclassesController < Admin::BaseController
  include ParamsDateConstructor
  skip_before_action :admin_account, only: [:show, :index, :new, :edit, :create, :update, :destroy, :repeat, :filter, :clear_filters, :instructor_select]
  before_action :junioradmin_account, only: [:new, :edit, :create, :update, :destroy, :repeat, :instructor_select]
  before_action :junioradmin_or_instructor_account, only: [:show, :index, :filter, :clear_filters]
  before_action :set_wkclass, only: [:show, :edit, :update, :destroy, :repeat]
  before_action :set_repeats, only: [:create, :repeat]
  before_action :set_bookings_and_purchase, only: :repeat
  before_action :single_booking_check, only: :repeat
  before_action :attendance_remain_check, only: :repeat
  before_action :affects_waiting_list, only: :update
  before_action :date_change, only: :update
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  # callback failed. don't know why. called update_purchase_status method explicitly in destroy method instead
  # resolution i think? @purchases is an active record collection so already array like so try update_purchase_status(@purchases) - no square brackets
  # after_action -> { update_purchase_status([@purchases]) }, only: %i[ destroy ]

  def index
    # Bullet would prefer us to counter_cache than load uncancelled_bookings as all we need is the size of the association, however counter_cache doesn't work for scoped associations
    # and i'm not minded to roll this myself given it isn't causing any major performance issue
    # https://stackoverflow.com/questions/37029847/counter-cache-in-rails-on-a-scoped-association
    # could counter cache the waitings if desired - https://blog.appsignal.com/2018/06/19/activerecords-counter-cache.html gives explanation of populating the counter_cache for objects that predate the counter 
    @wkclasses = Wkclass.includes([:uncancelled_bookings, :workout, :bookings, :instructor, :waitings]).order_by_date
    handle_filter
    handle_period
    # @wkclasses = @wkclasses.page params[:page]
    @workouts = Workout.order_by_name.current
    @months = ['All'] + months_logged
    @wkclass_times = ['All'] + Wkclass.start_times
    handle_pagination
    session[:show_qualifying_purchases] = nil if params[:show_qualifying_purchases] == 'no'
    handle_index_response
  end

  def show
    @bookings = @wkclass.uncancelled_bookings.order_by_status
    @cancelled_bookings_no_amnesty = @wkclass.cancelled_bookings.no_amnesty.order_by_status
    @cancelled_bookings_amnesty = @wkclass.cancelled_bookings.amnesty.order_by_status
    @waitings = @wkclass.waitings.order_by_created
    session[:show_qualifying_purchases] ||= params[:show_qualifying_purchases] || 'no'
    if session[:show_qualifying_purchases] == 'yes'
      @booking = Booking.new
      @qualifying_purchases = Purchase.qualifying_purchases(@wkclass)
    end
    # this section (which enbabled scrolling through the wkclassess) is redundant now we are hotwired
    # check_record_returned
    @link_from = params[:link_from]
    @page = params[:page] if @link_from == 'wkclasses_index'
    @purchase_link_from_id = params[:purchase_link_from_id] if @link_from == 'purchase_show'
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @wkclass = Wkclass.new
    @form_cancel_link = wkclasses_path
    prepare_items_for_dropdowns
  end

  def edit
    prepare_items_for_dropdowns
    @workout = @wkclass.workout
    @link_from = params[:link_from]
    @page = params[:page] if @link_from == 'wkclasses_index'
    @purchase_link_from_id = params[:purchase_link_from_id] if @link_from == 'purchase_show'
    # @form_cancel_link = wkclasses_path(link_from: params[:link_from], page: params[:page])
    # @form_cancel_link = params[:link_from] == 'purchases_index' ? wkclass_path(@wkclass, link_from: 'purchases_index') : wkclasses_path
  end

  def create
    if @repeats
      # activerecord takes the constituent bits of a date from the params and builds the date before saving. To advance the adate when there are repeats we have to go through the rigmarole of building the date, advancing and deconstructing
      start_date = construct_date(wkclass_params)
      @wkclasses = (0..@weeks_to_repeat).map { |weeks| Wkclass.create(wkclass_params.merge(deconstruct_date(start_date, weeks))) }
      if @wkclasses.all?(&:persisted?)
        redirect_to wkclasses_path
        flash[:success] = t('.success', repeats: "#{@weeks_to_repeat + 1} classes were")
      else
        @wkclass = @wkclasses.select(&:invalid?).first
        prepare_items_for_dropdowns
        render :new, status: :unprocessable_entity
      end
    else
      @wkclass = Wkclass.new(wkclass_params)
      if @wkclass.save
        redirect_to wkclasses_path
        flash[:success] = t('.success', repeats: '1 class was')
      else
        prepare_items_for_dropdowns
        render :new, status: :unprocessable_entity
      end
    end
  end

  def update
    @link_from = params[:wkclass][:link_from]
    @page = params[:wkclass][:page] if @link_from == 'wkclasses_index'
    @purchase_link_from_id = params[:wkclass][:purchase_link_from_id] if @link_from == 'purchase_show'    
    if @wkclass.update(wkclass_params)
      update_purchase_status(@wkclass.purchases) if @wkclass.bookings.no_amnesty.present? && @date_change
      notify_waiting_list(@wkclass) if @affects_waiting_list
      redirect_to wkclasses_path(page: @page, purchase_link_from_id: @purchase_link_from_id, link_from: @link_from)
      flash_message :success, t('.success')
    else
      prepare_items_for_dropdowns
      @workout = @wkclass.workout
      @instructor_id = @wkclass.instructor&.id
      @instructor_rate = @wkclass.instructor_rate&.id
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @purchases = @wkclass.bookings.map(&:purchase)
    @wkclass.destroy
    update_purchase_status(@purchases)
    redirect_to wkclasses_path(page: params[:page])
    flash[:success] = t('.success')
  end

  def repeat
    wkclasses_added = []
    bookings_added = []
    if @repeats
      (1..@weeks_to_repeat).map do |weeks|
        wkclass_repeat = @wkclass.dup
        wkclass_repeat.update(start_time: @wkclass.start_time.advance(weeks:))
        booking_repeat = wkclass_repeat.bookings.create(purchase_id: @purchase.id, status: 'booked') if wkclass_repeat.persisted? # cant see in what situation it would not be persisted
        wkclasses_added << wkclass_repeat
        bookings_added << booking_repeat
      end
      redirect_to wkclasses_path
      # NOTE: the all? method returns true when called on an empty array.
      if wkclasses_added.all?(&:persisted?) && bookings_added.all?(&:persisted?)
        flash[:success] = t('.success', repeats: "#{@weeks_to_repeat} classes and bookings were")
      elsif wkclasses_added.all?(&:persisted?)
        invalid_booking = bookings_added.select(&:invalid?).first
        flash[:warning] = t('.partial_success_booking', date_of_first_error: invalid_booking.wkclass.start_time.to_date.strftime('%d %b %y'))
      else
        invalid_wkclass = wkclasses_added.select(&:invalid?).first
        flash[:warning] = t('.partial_success_wkclass', date_of_first_error: invalid_wkclass.start_time.to_date.strftime('%d %b %y'))        
      end
    else
      flash[:warning] = t('.error')
    end
  end

  def clear_filters
    # splat operator * is used to turn array into an argument list
    # https://ruby-doc.org/core-2.0.0/doc/syntax/calling_methods_rdoc.html#label-Array+to+Arguments+Conversion
    clear_session(*session_filter_list)
    redirect_to wkclasses_path
  end

  def filter
    clear_session(*session_filter_list)
    session[:classes_period] = params[:classes_period]
    (params_filter_list - [:classes_period]).each do |item|
      session["filter_#{item}".to_sym] = params[item]
    end
    redirect_to wkclasses_path
  end

  def instructor_select
    workout = Workout.where(id: params[:selected_workout_id])&.first
    @instructor_rates = Instructor.where(id: params[:selected_instructor_id])&.first&.instructor_rates&.current&.order_by_group_instructor_rate || []
    (@instructor_rates = @instructor_rates.select(&:group?)) if workout&.group_workout?
    (@instructor_rates = @instructor_rates.reject(&:group?)) if workout&.pt_workout?
    render layout: false
  end

  private

  def set_bookings_and_purchase
    @bookings = @wkclass.bookings
    @purchase = @bookings.first.purchase
  end

  def single_booking_check
    return if @bookings.size == 1

    flash[:warning] = 'No classes created. There must be 1 and only 1 booking for this class.' # t('.not_one_booking')
    redirect_to wkclass_path(@wkclass, link_from: params[:wkclass][:link_from])
  end

  def attendance_remain_check
    attendances_remain = @bookings.first.purchase.attendances_remain

    return if attendances_remain == 'unlimited' # nutrition?
    
    return if @bookings.first.purchase.attendances_remain >= @weeks_to_repeat

    flash[:warning] = 'No classes created. Number of repeats exceeds the number of bookings that remain on the Package' # t('.repeats_too_high')
    redirect_to wkclass_path(@wkclass, link_from: params[:wkclass][:link_from])
  end

  def set_repeats
    repeats = params[:wkclass][:repeats]
    if repeats && !repeats.to_i.zero?
      @repeats = true
      # guard against somehow getting a huge number of repeats and blowing the system
      @weeks_to_repeat = [11, params[:wkclass][:repeats].to_i].min
    else
      @repeats = false
    end
  end

  # def construct_date(hash)
  #   DateTime.new(hash['start_time(1i)'].to_i,
  #                hash['start_time(2i)'].to_i,
  #                hash['start_time(3i)'].to_i)
  # end

  # def deconstruct_date(date, n)
  #   advanced_date = date.advance(weeks: n)
  #   { 'start_time(1i)': advanced_date.year.to_s,
  #     'start_time(2i)': advanced_date.month.to_s,
  #     'start_time(3i)': advanced_date.day.to_s }
  # end

  def date_change
    @date_change = false
    start_date = @wkclass.start_time.to_date
    proposed_start_date = construct_date(wkclass_params)
    @date_change = true if proposed_start_date != start_date
  end

  def affects_waiting_list
    @affects_waiting_list = false

    @affects_waiting_list = true if @wkclass.at_capacity? && wkclass_params[:max_capacity].to_i > @wkclass.max_capacity
  end

  def set_wkclass
    @wkclass = Wkclass.find(params[:id])
  end

  def wkclass_params
    cost = InstructorRate.find(params[:wkclass][:instructor_rate_id]).rate if params[:wkclass][:instructor_rate_id].present?
    params.require(:wkclass).permit(:workout_id, :start_time, :instructor_id, :instructor_rate_id, :max_capacity, :level, :studio, :duration)
          .merge({ instructor_cost: cost })
  end

  def params_filter_list
    [:any_workout_of, :in_workout_group, :at_time, :todays_class, :yesterdays_class, :tomorrows_class, :past, :future, :problematic, :classes_period]
  end

  def session_filter_list
    params_filter_list.map { |i| i == :classes_period ? i : "filter_#{i}" }
  end

  def prepare_items_for_dropdowns
    # @workouts = Workout.all.map { |w| [w.name, w.id] }
    @workouts = Workout.current.order_by_name
    @instructors = Instructor.current.has_rate.order_by_name
    @instructor_rates = @wkclass&.instructor&.instructor_rates&.current&.order_by_group_instructor_rate || []
    (@instructor_rates = @instructor_rates.select(&:group?)) if @wkclass&.workout&.group_workout?
    @capacities = (0..30).to_a + [500]
    @repeats = (0..11).to_a if @wkclass.new_record?
    @levels = Setting.levels # ['Beginner Friendly', 'All Levels', 'Intermediate']
    @studios = Setting.studios # ['Cellar', 'Window', 'Garden', 'Den']
    @durations = Setting.durations
    @instructor_id = @wkclass.instructor&.id
    @instructor_rate = @wkclass.instructor_rate&.id
  end

  def handle_filter
    %w[any_workout_of in_workout_group].each do |key|
      @wkclasses = @wkclasses.send(key, session["filter_#{key}"]) if session["filter_#{key}"].present?
      # @wkclasses = Wkclass.where(id: @wkclasses.map(&:id)) if @wkclasses.is_a?(Array)
    end
    %w[todays_class yesterdays_class tomorrows_class past future problematic].each do |key|
      @wkclasses = @wkclasses.send(key) if session["filter_#{key}"].present?
    end
    # at_time isn't a scope so manage separately
    if session[:filter_at_time].present?
      @wkclasses = @wkclasses.send(:at_time, session[:filter_at_time])
    end
  end

  def handle_period
    return unless session[:classes_period].present? && session[:classes_period] != 'All'

    @wkclasses = @wkclasses.during(month_period(session[:classes_period]))
  end

  def handle_pagination
    # when exporting data, want it all not just the page of pagination
    if params[:export_all]
      @pagy, @wkclasses = pagy(@wkclasses, items: 100_000)
    else
      @pagy, @wkclasses = pagy(@wkclasses, items: Setting.wkclasses_pagination)
    end
  end

  def handle_index_response
    respond_to do |format|
      format.html
      # Railscasts #362 Exporting Csv And Excel
      # https://www.youtube.com/watch?v=SelheZSdZj8
      format.csv { send_data @wkclasses.to_csv }
      format.turbo_stream
    end
  end

  def record_not_found
    flash[:danger] = t('.record_not_found')
    redirect_to wkclasses_path
  end

  def check_record_returned
    return if @wkclasses.pluck(:id).include? params[:id].to_i

    flash[:danger] = t('.record_not_returned')
    redirect_to wkclasses_path
  end

end
