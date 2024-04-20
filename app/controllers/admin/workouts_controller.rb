class Admin::WorkoutsController < Admin::BaseController
  before_action :set_workout, only: [:show, :edit, :update, :destroy]

  def index
    @workouts = Workout.order_by_current
    @workouts = @workouts.current if session[:filter_workout_active].present?
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
    byebug
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

  private

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
