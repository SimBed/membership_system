class Admin::WorkoutsController < Admin::BaseController
  before_action :set_workout, only: [:show, :edit, :update, :destroy]

  def index
    @workouts = Workout.all
  end

  def show; end

  def new
    @workout = Workout.new
    #    @instructors = Instructor.all.map { |i| ["#{i.first_name} #{i.last_name}", i.id] }
  end

  def edit
    #    @instructors = Instructor.all.map { |i| ["#{i.first_name} #{i.last_name}", i.id] }
  end

  def create
    @workout = Workout.new(workout_params)

    if @workout.save
      redirect_to admin_workouts_path
      flash[:success] = 'Workout was successfully created.'
    else
      #        @instructors = Instructor.all.map { |i| ["#{i.first_name} #{i.last_name}", i.id] }
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @workout.update(workout_params)
      redirect_to admin_workouts_path
      flash[:success] = 'Workout was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workout.destroy
    redirect_to admin_workouts_path
    flash[:success] = 'Workout was successfully deleted.'
  end

  private

  def set_workout
    @workout = Workout.find(params[:id])
  end

  def workout_params
    params.require(:workout).permit(:name)
  end
end
