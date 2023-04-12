class Admin::WorkoutsController < Admin::BaseController
  before_action :set_workout, only: [:show, :edit, :update, :destroy]

  def index
    @workouts = Workout.order_by_current
    @workouts = @workouts.current if session[:filter_workout_active].present?
    respond_to do |format|
      format.html
      format.js { render 'index.js.erb' }
    end    
  end

  def show; end

  def new
    @workout = Workout.new
  end

  def edit; end

  def create
    @workout = Workout.new(workout_params)

    if @workout.save
      redirect_to admin_workouts_path
      flash[:success] = t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @workout.update(workout_params)
      redirect_to admin_workouts_path
      flash[:success] = t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workout.destroy
    redirect_to admin_workouts_path
    flash[:success] = t('.success')
  end

  def filter
    clear_session(:filter_workout_active)
    session[:filter_workout_active] = params[:active]
    redirect_to admin_workouts_path
  end

  private

  def set_workout
    @workout = Workout.find(params[:id])
  end

  def workout_params
    # the update method (and therefore the workout_params method) is used through a form but also clicking on a link on the workouts page
    return {current: params[:current] } if params[:current].present?

    params.require(:workout).permit(:name, :current, :instructor_initials)
  end
end
