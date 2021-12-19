class WorkoutGroupsController < ApplicationController
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
        redirect_to @workout_group
        flash[:success] = "Workout Group was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
  end

  def update
    respond_to do |format|
      if @workout_group.update(name: params[:workout_group][:name], workout_ids: params[:workout_ids])
        format.html { redirect_to @workout_group, notice: "Workout Group was successfully updated." }
        format.json { render :show, status: :ok, location: @workout_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @workout_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @workout_group.destroy
    respond_to do |format|
      format.html { redirect_to workout_groups_url, notice: "Workout Group was successfully destroyed." }
      format.json { head :no_content }
    end
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
