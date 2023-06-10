class Admin::WkclassesController < Admin::BaseController
  skip_before_action :admin_account, only: [:show, :index, :new, :edit, :create, :update, :destroy, :repeat, :filter, :instructor]
  before_action :junioradmin_account, only: [:show, :index, :new, :edit, :create, :update, :destroy, :repeat, :instructor]
  before_action :set_wkclass, only: [:show, :edit, :update, :destroy, :repeat]
  before_action :set_repeats, only: [:create, :repeat]
  before_action :attendance_check, only: :repeat
  before_action :attendance_remain_check, only: :repeat
  # callback failed. don't know why. called update_purchase_status method explicitly in destroy method instead
  # resolution i think? @purchases is an active record collection so already array like so try update_purchase_status(@purchases) - no square brackets
  # after_action -> { update_purchase_status([@purchases]) }, only: %i[ destroy ]

  def index
    # Bullet would prefer us to counter_cache than load physical attendances as all we need is the size of the association, however counter_cache doesn't work for scoped associations
    # and i'm not minded to roll this myself given it isn't causing any major performance issue
    # https://stackoverflow.com/questions/37029847/counter-cache-in-rails-on-a-scoped-association
    @wkclasses = Wkclass.includes([:physical_attendances, :workout, :attendances, :instructor]).order_by_date
    handle_filter
    handle_period
    @wkclasses = @wkclasses.page params[:page]
    @workouts = Workout.order_by_name.current
    @months = ['All'] + months_logged
    handle_export
    handle_index_response
  end

  def show
    @physical_attendances = @wkclass.physical_attendances.order_by_status
    @ethereal_attendances_no_amnesty = @wkclass.ethereal_attendances.no_amnesty.order_by_status
    @ethereal_attendances_amnesty = @wkclass.ethereal_attendances.amnesty.order_by_status
    # @attended = @wkclass.attendances.no_amnesty.order_by_status
    # @amnesties = @wkclass.attendances.amnesty.order_by_status
    # if the 'wkclass show comes from the client_attendances_table and the date of that class is not in the period filter
    # from the wkclass index filter form, the next_item helper will fail (unless the classes_period is reset to be consistent with the wkclass to be shown)
    # clear_session(:filter_workout, :filter_spacegroup, :filter_todays_class, :filter_yesterdays_class, :filter_tomorrows_class, :filter_past, :filter_future, :classes_period) if params[:setting] == 'clientshow'
    # session[:classes_period] = params[:classes_period] || session[:classes_period]
    # set @wkclasses and @wkindex so the wkclasses can be scrolled through from each wkclass show
    return if params[:no_scroll]

    @wkclasses = Wkclass.order_by_date
    handle_filter
    handle_period
    # @wkindex = @wkclasses.index(@wkclass)
  end

  def new
    @wkclass = Wkclass.new
    prepare_items_for_dropdowns
  end

  def edit
    prepare_items_for_dropdowns
    @workout = @wkclass.workout
    # @instructor_id = @wkclass.instructor&.id
    # @instructor_rate = @wkclass.instructor_rate&.id
  end

  def create
    if @repeats
      # activerecord takes the constiruent bits of a date from the params and builds the date before saving. To advance the adate when there are repeats we have to go through the rigmaroll of building the date, advancing and deconstructiong
      start_date = construct_date(wkclass_params)
      @wkclasses = (0..@weeks_to_repeat).map { |weeks| Wkclass.create(wkclass_params.merge(deconstruct_date(start_date, weeks))) }
      if @wkclasses.all?(&:persisted?)
        redirect_to admin_wkclasses_path
        flash[:success] = t('.success', repeats: "#{@weeks_to_repeat + 1} classes were")
      else
        @wkclass = @wkclasses.select(&:invalid?).first
        prepare_items_for_dropdowns
        render :new, status: :unprocessable_entity
      end
    else
      @wkclass = Wkclass.new(wkclass_params)
      if @wkclass.save
        redirect_to admin_wkclass_path(@wkclass, no_scroll: true)
        flash[:success] = t('.success', repeats: '1 class was')
      else
        prepare_items_for_dropdowns
        render :new, status: :unprocessable_entity
      end
    end
  end

  def update
    if @wkclass.update(wkclass_params)
      redirect_to admin_wkclasses_path
      flash[:success] = t('.success')
    else
      prepare_items_for_dropdowns
      @workout = @wkclass.workout
      @instructor_id = @wkclass.instructor&.id
      @instructor_rate = @wkclass.instructor_rate&.id
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @purchases = @wkclass.attendances.map(&:purchase)
    @wkclass.destroy
    update_purchase_status(@purchases)
    redirect_to admin_wkclasses_path
    flash[:success] = t('.success')
  end

  def repeat
    wkclasses = []
    if @repeats
      @wkclasses = (1..@weeks_to_repeat).map do |weeks|
        wkclass = @wkclass.dup
        attendance = @attendances.first.dup
        wkclass.update(start_time: wkclass.start_time.advance(weeks: weeks))
        wkclasses << wkclass
        attendance.dup.update(wkclass_id: wkclass.id, status: 'booked') if wkclass.persisted?
      end
      redirect_to admin_wkclasses_path
      # NOTE: the all? method returns true when called on an empty array.
      if wkclasses.all?(&:persisted?)
        flash[:success] = t('.success', repeats: "#{@weeks_to_repeat} classes were")
      else
        wkclass = wkclasses.select(&:invalid?).first
        flash[:warning] = t('.partial_success', date_of_first_error: wkclass.start_time.to_date)
      end
    else
      flash[:warning] = t('.error')
    end
  end

  def filter
    clear_session(*session_filter_list)
    session[:classes_period] = params[:classes_period]
    (params_filter_list - [:classes_period]).each do |item|
      session["filter_#{item}".to_sym] = params[item]
    end
    redirect_to admin_wkclasses_path
  end

  def instructor
    # @instructor_rates = Instructor&.find(params[:selected_instructor_id])&.instructor_rates
    workout = Workout.where(id: params[:selected_workout_id])&.first
    @instructor_rates = Instructor.where(id: params[:selected_instructor_id])&.first&.instructor_rates&.current&.order_for_index || []
    (@instructor_rates = @instructor_rates.select(&:group?)) if workout&.group_workout?
    render 'instructor.js.erb'
  end

  private

  def attendance_check
    @attendances = @wkclass.attendances
    return if @attendances.size == 1

    flash[:warning] = 'No classes created. There must be 1 and only 1 booking for this class.' # t('.not_one_booking')
    redirect_to admin_wkclass_path(@wkclass, no_scroll: true)
  end

  def attendance_remain_check
    return if @attendances.first.purchase.attendances_remain >= @weeks_to_repeat

    flash[:warning] = 'No classes created. Number of repeats exceeds the number of bookings that remain on the Package' # t('.repeats_too_high')
    redirect_to admin_wkclass_path(@wkclass, no_scroll: true)
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

  def construct_date(hash)
    DateTime.new(hash['start_time(1i)'].to_i,
                 hash['start_time(2i)'].to_i,
                 hash['start_time(3i)'].to_i)
  end

  def deconstruct_date(date, n)
    advanced_date = date.advance(weeks: n)
    { 'start_time(1i)': advanced_date.year.to_s,
      'start_time(2i)': advanced_date.month.to_s,
      'start_time(3i)': advanced_date.day.to_s, }
  end

  def set_wkclass
    @wkclass = Wkclass.find(params[:id])
  end

  def wkclass_params
    # if Instructor.exists?(params[:wkclass][:instructor_id])
    #   cost = Instructor.find(params[:wkclass][:instructor_id]).current_rate
    # end
    # # cost is nil in client_booking_interface_test when admin just updates wkclass time, hence the nil protecting '&'
    # cost = nil if cost&.zero?
    cost = InstructorRate.find(params[:wkclass][:instructor_rate_id]).rate
    params.require(:wkclass).permit(:workout_id, :start_time, :instructor_id, :instructor_rate_id, :max_capacity, :level)
          .merge({ instructor_cost: cost })
  end

  def params_filter_list
    [:any_workout_of, :in_workout_group, :todays_class, :yesterdays_class, :tomorrows_class, :past, :future, :problematic, :classes_period]
  end

  def session_filter_list
    params_filter_list.map { |i| i == :classes_period ? i : "filter_#{i}" }
  end

  def prepare_items_for_dropdowns
    # @workouts = Workout.all.map { |w| [w.name, w.id] }
    @workouts = Workout.current.order_by_name
    @instructors = Instructor.current.has_rate.order_by_name
    @instructor_rates = @wkclass&.instructor&.instructor_rates&.current&.order_for_index || []
    (@instructor_rates = @instructor_rates.select(&:group?)) if @wkclass&.workout&.group_workout?
    @capacities = (0..30).to_a + [500]
    @repeats = (0..11).to_a if @wkclass.new_record?
    @levels = ['Beginner Friendly', 'All Levels', 'Intermediate']
    @instructor_id = @wkclass.instructor&.id
    @instructor_rate = @wkclass.instructor_rate&.id
  end

  def handle_filter
    %w[any_workout_of in_workout_group].each do |key|
      @wkclasses = @wkclasses.send(key, session["filter_#{key}"]) if session["filter_#{key}"].present?
    end
    %w[todays_class yesterdays_class tomorrows_class past future problematic].each do |key|
      @wkclasses = @wkclasses.send(key) if session["filter_#{key}"].present?
    end
  end

  def handle_period
    return unless session[:classes_period].present? && session[:classes_period] != 'All'

    @wkclasses = @wkclasses.during(month_period(session[:classes_period]))
  end

  def handle_export
    # when exporting data, want it all not just the page of pagination
    @wkclasses = if params[:export_all]
                   @wkclasses.page(params[:page]).per(100_000)
               else
                 @wkclasses.page params[:page]
               end
  end

  def handle_index_response
    respond_to do |format|
      format.html
      format.js { render 'index.js.erb' }
      # Railscasts #362 Exporting Csv And Excel
      # https://www.youtube.com/watch?v=SelheZSdZj8
      format.csv { send_data @wkclasses.to_csv }
    end
  end
end
