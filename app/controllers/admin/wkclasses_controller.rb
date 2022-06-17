class Admin::WkclassesController < Admin::BaseController
  skip_before_action :admin_account, only: [:show, :index, :new, :edit, :create, :update, :filter]
  before_action :junioradmin_account, only: [:show, :index, :new, :edit, :create, :update]
  before_action :set_wkclass, only: [:show, :edit, :update, :destroy]
  # callback failed. don't know why. called update_purchase_status method explicitly in destroy method instead
  # resolution i think? @purchases is an active record collection so already array like so try update_purchase_status(@purchases) - no square brackets
  # after_action -> { update_purchase_status([@purchases]) }, only: %i[ destroy ]

  def index
    @wkclasses = Wkclass.includes([:confirmed_attendances, :provisional_attendances, :workout]).order_by_date
    handle_filter
    handle_period
    @wkclasses = @wkclasses.page params[:page]
    @workout = Workout.distinct.pluck(:name).sort!
    @months = ['All'] + months_logged

    respond_to do |format|
      format.html
      format.js { render 'index.js.erb' }
    end
  end

  def show
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
    # for select in new wkclass form
    prepare_items_for_dropdowns
  end

  def edit
    prepare_items_for_dropdowns
    @workout = @wkclass.workout
    @instructor = @wkclass.instructor&.id
  end

  def create
    @wkclass = Wkclass.new(wkclass_params)
    if @wkclass.save
      redirect_to admin_wkclass_path(@wkclass, no_scroll: true)
      flash[:success] = t('.success')
      # @wkclass.delay.send_reminder
      # Wkclass.delay.send_reminder(@wkclass.id)
      # Wkclass.send_reminder(@wkclass.id)
    else
      # prepare_items_for_dropdowns
      prepare_items_for_dropdowns
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @wkclass.update(wkclass_params)
      redirect_to admin_wkclasses_path
      flash[:success] = t('.success')
    else
      prepare_items_for_dropdowns
      @workout = @wkclass.workout
      @instructor = @wkclass.instructor&.id
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

  def filter
    clear_session(*session_filter_list)
    session[:classes_period] = params[:classes_period]
    (params_filter_list - [:classes_period]).each do |item|
      session["filter_#{item}".to_sym] = params[item]
    end
    redirect_to admin_wkclasses_path
  end

  private

  def set_wkclass
    @wkclass = Wkclass.find(params[:id])
  end

  def wkclass_params
    if Instructor.exists?(params[:wkclass][:instructor_id])
      cost = Instructor.find(params[:wkclass][:instructor_id]).current_rate
    end
    # cost is nil in client_booking_interface_test when admin just updates wkclass time, hence the nil protecting '&'
    cost = nil if cost&.zero?
    params.require(:wkclass).permit(:workout_id, :start_time, :instructor_id,
                                    :max_capacity).merge({ instructor_cost: cost })
  end

  def params_filter_list
    [:any_workout_of, :in_workout_group, :todays_class, :yesterdays_class, :tomorrows_class, :past, :future,
     :classes_period]
  end

  def session_filter_list
    params_filter_list.map { |i| i == :classes_period ? i : "filter_#{i}" }
  end

  def prepare_items_for_dropdowns
    @workouts = Workout.all.map { |w| [w.name, w.id] }
    @instructors = Instructor.has_rate.order_by_name.map { |i| [i.name, i.id] }
  end

  def handle_filter
    %w[any_workout_of in_workout_group].each do |key|
      @wkclasses = @wkclasses.send(key, session["filter_#{key}"]) if session["filter_#{key}"].present?
    end
    %w[todays_class yesterdays_class tomorrows_class past future].each do |key|
      @wkclasses = @wkclasses.send(key) if session["filter_#{key}"].present?
    end
  end

  def handle_period
    return unless session[:classes_period].present? && session[:classes_period] != 'All'

    @wkclasses = @wkclasses.during(month_period(session[:classes_period]))
  end
end
