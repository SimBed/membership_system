class Admin::WorkoutsController < Admin::BaseController
  before_action :set_workout, only: [:show, :edit, :update, :destroy]

  def index
    @workouts = Workout.order_by_current
    handle_filter
    # @workouts = @workouts.current if session[:filter_workout_active].present?
    prepare_items_for_filters
    respond_to do |format|
      format.html
      format.turbo_stream
    end    
  end

  def show
    respond_to do |format|
      format.html
      format.turbo_stream
    end    
  end

  def new
    @workout = Workout.new
    prepare_items_for_dropdowns
  end

  def edit
    prepare_items_for_dropdowns
  end

  def create
    @workout = Workout.new(workout_params)

    if @workout.save
      redirect_to workouts_path
      flash[:success] = t('.success')
    else
      prepare_items_for_dropdowns    
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @workout.update(workout_params)
      redirect_to workouts_path
      flash[:success] = t('.success')
    else
      prepare_items_for_dropdowns   
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workout.destroy
    redirect_to workouts_path
    flash[:success] = t('.success')
  end

  def filter
    clear_session(:filter_workout_active)
    session[:filter_workout_active] = params[:active]
    redirect_to workouts_path
  end

  def filter
    clear_session(*session_filter_list)
    params_filter_list.each do |item|
      session["filter_#{item}".to_sym] = params[item]
    end
    redirect_to workouts_path
  end  

  private

  def params_filter_list
    [:in_workout_group, :current]
  end

  def session_filter_list
    params_filter_list.map { |i| "filter_#{i}" }
  end

  def handle_filter
     %w[current].each do |key|
      @workouts = @workouts.send(key) if session["filter_#{key}"].present?
    end
    %w[in_workout_group].each do |key|
      @workouts = @workouts.send(key, session["filter_#{key}"]) if session["filter_#{key}"].present?
    end
  end  

  def prepare_items_for_filters
    @workout_group = WorkoutGroup.distinct.pluck(:name).sort!
  end  

  def prepare_items_for_dropdowns
    @capacities = (0..30).to_a + [500]
    @styles = Setting.styles.sort
    @levels = Setting.levels.sort
    @warnings = Setting.warnings.sort
  end

  def set_workout
    @workout = Workout.find(params[:id])
  end

  def workout_params
    # the update method (and therefore the workout_params method) is used through a form but also clicking on a link on the workouts page
    return { current: params[:current] } if params[:current].present?

    params.require(:workout).permit(:name, :current, :default_capacity, :instructor_initials, :description, :level, :warning, styles: [])
  end
end
