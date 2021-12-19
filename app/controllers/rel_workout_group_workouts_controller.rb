class RelWorkoutGroupWorkoutsController < ApplicationController
  before_action :set_rel_workout_group_workout, only: %i[ show edit update destroy ]

  def index
    @rel_workout_group_workouts = RelWorkoutGroupWorkout.all
  end

  def show
  end

  def new
    @rel_workout_group_workout = RelWorkoutGroupWorkout.new
  end

  def edit
  end

  def create
    @rel_workout_group_workout = RelWorkoutGroupWorkout.new(rel_workout_group_workout_params)

      if @rel_workout_group_workout.save
        redirect_to @rel_workout_group_workout
        flash[:success] = "Rel workout group workout was successfully created"
      else
        render :new, status: :unprocessable_entity
      end
  end

  def update
      if @rel_workout_group_workout.update(rel_workout_group_workout_params)
        redirect_to @rel_workout_group_workout
        flash[:success] = "Rel workout group workout was successfully updated"
      else
        render :edit, status: :unprocessable_entity
      end
  end

  def destroy
    @rel_workout_group_workout.destroy
    redirect_to rel_workout_group_workouts_url
    flash[:success] = "Rel workout group workout was successfully destroyed"
  end

  private
    def set_rel_workout_group_workout
      @rel_workout_group_workout = RelWorkoutGroupWorkout.find(params[:id])
    end

    def rel_workout_group_workout_params
      params.require(:rel_workout_group_workout).permit(:workout_group_id, :workout_ids)
    end
end
