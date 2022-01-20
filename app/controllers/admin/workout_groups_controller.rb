class Admin::WorkoutGroupsController < Admin::BaseController
  before_action :set_workout_group, only: %i[ show edit update destroy ]

  def index
    @workout_groups = WorkoutGroup.all
  end

  def show
  end

  def new
    @workout_group = WorkoutGroup.new
    @workouts = Workout.all
  end

  def edit
    @workouts = Workout.all
  end

  def create
    @workout_group = WorkoutGroup.new(name: params[:workout_group][:name], workout_ids: params[:workout_ids])
      if @workout_group.save
        redirect_to admin_workout_group_path(@workout_group)
        flash[:success] = "Workout Group was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
  end

  def update
      if @workout_group.update(name: params[:workout_group][:name], workout_ids: params[:workout_ids])
        redirect_to admin_workout_group_path(@workout_group)
        flash[:success] = "Workout Group was successfully updated."
      else
        @workouts = Workout.all
        render :edit, status: :unprocessable_entity
      end
  end

  def destroy
    @workout_group.destroy
      redirect_to admin_workout_groups_path
      flash[:success] = "Workout Group was successfully destroyed."
  end

  private
    def set_workout_group
      @workout_group = WorkoutGroup.find(params[:id])
    end

    # not used
    def workout_group_params
      params.require(:workout_group).permit(:name)
    end

end
