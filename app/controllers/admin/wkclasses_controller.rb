require 'byebug'
class Admin::WkclassesController < Admin::BaseController
  skip_before_action :admin_account, only: %i[ show index new edit create update filter ]
  before_action :junioradmin_account, only: %i[ show index new edit create update ]
  before_action :set_wkclass, only: %i[ show edit update destroy ]

  def index
    @wkclasses = Wkclass.includes([:confirmed_attendances, :provisional_attendances, :workout]).order_by_date
    handle_search
    @wkclasses = @wkclasses.page params[:page]
    @workout = Workout.distinct.pluck(:name).sort!
    @months = ['All'] + months_logged

    respond_to do |format|
      format.html {}
      format.js {render 'index.js.erb'}
    end
  end

  def show
    # if the 'wkclass show comes from the client_attendances_table and the date of that class is not in the period filter
    # from the wkclass index filter form, the next_item helper will fail (unless the classes_period is reset to be consistent with the wkclass to be shown)
    clear_session(:filter_workout, :filter_spacegroup, :filter_todays_class, :filter_yesterdays_class, :filter_tomorrows_class, :filter_past, :filter_future, :classes_period)
    session[:classes_period] = params[:classes_period] || session[:classes_period]
    # set @wkclasses and @wkindex so the wkclasses can be scrolled through from each wkclass show
    @wkclasses = Wkclass.order_by_date
    handle_search
    @wkindex = @wkclasses.index(@wkclass)
  end

  def new
    @wkclass = Wkclass.new
    # for select in new wkclass form
    @workouts = Workout.all.map { |w| [w.name, w.id] }
    @instructors =  Instructor.order_by_name.map { |i| [i.name, i.id] }
  end

  def edit
    @workouts = Workout.all.map { |w| [w.name, w.id] }
    @workout = @wkclass.workout
    @instructors =  Instructor.order_by_name.map { |i| [i.name, i.id] }
    @instructor = @wkclass.instructor&.id
  end

  def create
    @wkclass = Wkclass.new(wkclass_params)
      if @wkclass.save
        redirect_to admin_wkclass_path(@wkclass)
        flash[:success] = "Class was successfully created"
      else
        @workouts = Workout.all.map { |w| [w.name, w.id] }
        @instructors =  Instructor.order_by_name.map { |i| [i.name, i.id] }
        render :new, status: :unprocessable_entity
      end
  end

  def update
      if @wkclass.update(wkclass_params)
        redirect_to admin_wkclasses_path
        flash[:success] = "Class was successfully updated"
      else
        render :edit, status: :unprocessable_entity
      end
  end

  def destroy
    @wkclass.destroy
    redirect_to admin_wkclasses_path
    flash[:success] = "Class was successfully deleted"
  end

  def filter
    # see application_helper
    clear_session(:filter_workout, :filter_spacegroup, :filter_todays_class, :filter_yesterdays_class, :filter_tomorrows_class, :filter_past, :filter_future, :classes_period)
    session[:filter_workout] = params[:workout] || session[:filter_workout]
    session[:filter_spacegroup] = params[:spacegroup] || session[:filter_spacegroup]
    session[:classes_period] = params[:classes_period] || session[:classes_period]
    session[:filter_todays_class] = params[:todays_class] || session[:filter_todays_class]
    session[:filter_yesterdays_class] = params[:yesterdays_class] || session[:filter_yesterdays_class]
    session[:filter_tomorrows_class] = params[:tomorrows_class] || session[:filter_tomorrows_class]
    session[:filter_past] = params[:past] || session[:filter_past]
    session[:filter_future] = params[:future] || session[:filter_future]
    redirect_to admin_wkclasses_path
  end

  private
    def set_wkclass
      @wkclass = Wkclass.find(params[:id])
    end

    def wkclass_params
      wk_p = params.require(:wkclass).permit(:workout_id, :start_time, :instructor_id)
      cost = Instructor&.find(wk_p[:instructor_id]).current_rate if Instructor.exists?(wk_p[:instructor_id])
      wk_p.merge({ instructor_cost: cost })
    end

    def handle_search

      @wkclasses = Wkclass.joins(:workout).where(workout: { name: session[:filter_workout] }).order(start_time: :desc) if session[:filter_workout].present?
      @wkclasses = @wkclasses.in_workout_group(session[:filter_spacegroup]) if session[:filter_spacegroup].present?
      @wkclasses = @wkclasses.todays_class if session[:filter_todays_class].present?
      @wkclasses = @wkclasses.yesterdays_class if session[:filter_yesterdays_class].present?
      @wkclasses = @wkclasses.tomorrows_class if session[:filter_tomorrows_class].present?
      @wkclasses = @wkclasses.past if session[:filter_past].present?
      @wkclasses = @wkclasses.future if session[:filter_future].present?
      if session[:classes_period].present? && !(session[:classes_period] == 'All')
        start_date = Date.parse(session[:classes_period])
        end_date = Date.parse(session[:classes_period]).end_of_month.end_of_day
        @wkclasses = @wkclasses.between(start_date, end_date)
      end
    end
end
