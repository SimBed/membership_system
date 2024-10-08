class Admin::TimetablesController < Admin::BaseController
  skip_before_action :admin_account, only: [:show_public, :show]
  before_action :junioradmin_account, only: :show
  before_action :set_timetable, only: [:show, :edit, :update, :destroy, :deep_copy]
  before_action :set_active_timetables, only: :index

  def index
    @timetables = Timetable.order_by_date_until
    unique_current_timetable
  end

  def show
    # could build a entries hash to avoid database lookups in the view
    @days = @timetable.table_days.order_by_day
    @colspan = @days.size + 1
    @morning_times = @timetable.table_times.during('morning').order_by_time
    @afternoon_times = @timetable.table_times.during('afternoon').order_by_time
    @evening_times = @timetable.table_times.during('evening').order_by_time
    render layout: 'timetable'
  end

  def public_format
    @entries_hash = Timetable.display_entries(show_publicly_invisible: true)
    render 'public_pages/timetable', layout: 'public'
  end

  def new
    @timetable = Timetable.new
  end

  def edit; end

  def create
    @timetable = Timetable.new(timetable_params)
    if @timetable.save
      flash[:success] = t('.success')
      redirect_to timetable_path(@timetable)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @timetable.update(timetable_params)
      flash[:success] = t('.success')
      redirect_to timetables_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @timetable.destroy
    flash[:success] = t('.success')
    redirect_to timetables_path
  end

  def deep_copy
    #TODO: validate: false added as TableDay#no_repeated_days fails with validations. Don't see any problem with not running validations, but perhaps more robust to 
    # investigate more why this happens and perhaps solve by adding return nil if inputs are nil to for_day_of_week method  
    t_copy = @timetable.deep_clone include: [ {table_days: :entries}, { table_times: :entries} ], use_dictionary: true, validate: false
    t_copy.update(title: "#{t_copy.title} (copy)") # NOTE: update saves record
    flash[:success] = t('.success')
    redirect_to timetables_path    
  end

  private

  def set_active_timetables
    @active_display = Timetable.actives_at(Time.zone.now).first
    wkclass_date = Time.zone.now.advance(days: Rails.application.config_for(:constants)['wkclassmaker_advance'])
    @active_build = Timetable.actives_at(wkclass_date).first
  end

  def unique_current_timetable
    case Timetable.current_at(Time.zone.now).size
    when 0 
      @uniqueness_error = true
      @uniqueness_error_message = "There is no timetable active at today's date."
    when 1
      @uniqueness_error = false
    else
      @uniqueness_error = true
      @uniqueness_error_message = "There is more than 1 timetable current at today's date."
    end
  end

  def set_timetable
    @timetable = Timetable.find(params[:id])
  end

  def timetable_params
    params.require(:timetable).permit(:title, :date_from, :date_until)
  end
end
