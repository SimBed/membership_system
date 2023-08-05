class Admin::TimetablesController < Admin::BaseController
  skip_before_action :admin_account, only: [:show_public, :show]
  before_action :junioradmin_account, only: :show
  before_action :set_timetable, only: %i[ show edit update destroy ]

  def index
    @timetables = Timetable.all
  end

  def show
    # could build a entries hash to avoid database lookups in the view
    @days = @timetable.table_days.order_by_day
    @morning_times = @timetable.table_times.during('morning').order_by_time
    @afternoon_times = @timetable.table_times.during('afternoon').order_by_time
    @evening_times = @timetable.table_times.during('evening').order_by_time
    render layout: 'timetable'
  end

  def show_public
    @timetable = Timetable.find(Rails.application.config_for(:constants)['timetable_id'])
    @days = @timetable.table_days.order_by_day
    @entries_hash = {}
    @days.each do |day|
      @entries_hash[day.name] = Entry.where(table_day_id: day.id).includes(:table_time, :workout).order_by_start
    end
    # used to establish whether 2nd day in the timetable slider is tomorrow or not
    @tomorrows_day = Date.tomorrow.strftime("%A")    
    render 'public_pages/timetable', layout: 'public'
  end

  def new
    @timetable = Timetable.new
  end

  def edit
  end

  def create
    @timetable = Timetable.new(timetable_params)
    if @timetable.save
      flash_message :success, 'Timetable was successfully created.'
      redirect_to admin_timetable_path(@timetable)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @timetable.update(timetable_params)
      redirect_to admin_timetable_path(@timetable), notice: 'Timetable was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @timetable.destroy
    redirect_to admin_timetables_path, notice: 'Timetable was successfully deleted.'
  end

  private

  def set_timetable
    @timetable = Timetable.find(params[:id])
  end

  def timetable_params
    params.require(:timetable).permit(:title)
  end
end
