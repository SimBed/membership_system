class WkclassesController < ApplicationController
  before_action :set_wkclass, only: %i[ show edit update destroy ]

  def index
    @wkclasses = Wkclass.order_by_date
    handle_search
    @workout = Workout.distinct.pluck(:name).sort!
    @months = ['All'] + months_logged
  end

  def show
  end

  def new
    @wkclass = Wkclass.new
    # for select in new wkclass form
    @workouts = Workout.all.map { |w| [w.name, w.id] }
  end

  def edit
    @workouts = Workout.all.map { |w| [w.name, w.id] }
  end

  def create
    @wkclass = Wkclass.new(wkclass_params)
      if @wkclass.save
        redirect_to @wkclass
        flash[:success] = "Class was successfully created"
      else
        render :new, status: :unprocessable_entity
      end
  end

  def update
      if @wkclass.update(wkclass_params)
        redirect_to wkclasses_path
        flash[:success] = "Class was successfully updated"
      else
        render :edit, status: :unprocessable_entity
      end
  end

  def destroy
    @wkclass.destroy
    redirect_to wkclasses_url
    flash[:success] = "Class was successfully deleted"
  end

  def filter
    # see application_helper
    clear_session(:filter_workout, :classes_period)
    session[:filter_workout] = params[:workout] || session[:filter_workout]
    session[:classes_period] = params[:classes_period] || session[:classes_period]
    redirect_to wkclasses_path
  end

  private
    def set_wkclass
      @wkclass = Wkclass.find(params[:id])
    end

    def wkclass_params
      params.require(:wkclass).permit(:workout_id, :start_time)
    end

    def handle_search
      @wkclasses = Wkclass.joins(:workout).where(workout: { name: session[:filter_workout] }) if session[:filter_workout].present?
      if session[:classes_period].present? && !(session[:classes_period] == 'All')
        start_date = Date.parse(session[:classes_period])
        end_date = Date.parse(session[:classes_period]).end_of_month.end_of_day
        @wkclasses = @wkclasses.by_date(start_date, end_date)
      end
    end
end
