# require 'byebug'
class WorkoutGroupsController < ApplicationController
  before_action :set_workout_group, only: %i[ show edit update destroy ]

  # GET /workout_groups or /workout_groups.json
  def index
    @workout_groups = WorkoutGroup.all
  end

  # GET /workout_groups/1 or /workout_groups/1.json
  def show
  end

  # GET /workout_groups/new
  def new
    @workout_group = WorkoutGroup.new
    @workouts = Workout.all
  end

  # GET /workout_groups/1/edit
  def edit
    @workouts = Workout.all
  end

  # POST /workout_groups or /workout_groups.json
  def create
    # byebug
    @workout_group = WorkoutGroup.new(name: params[:workout_group][:name], workout_ids: params[:workout_ids])

    respond_to do |format|
      if @workout_group.save
        format.html { redirect_to @workout_group, notice: "Workout group was successfully created." }
        format.json { render :show, status: :created, location: @workout_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @workout_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /workout_groups/1 or /workout_groups/1.json
  def update
    respond_to do |format|
      if @workout_group.update(name: params[:workout_group][:name], workout_ids: params[:workout_ids])
        format.html { redirect_to @workout_group, notice: "Workout group was successfully updated." }
        format.json { render :show, status: :ok, location: @workout_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @workout_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /workout_groups/1 or /workout_groups/1.json
  def destroy
    @workout_group.destroy
    respond_to do |format|
      format.html { redirect_to workout_groups_url, notice: "Workout group was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_workout_group
      @workout_group = WorkoutGroup.find(params[:id])
    end

    # not used
    def workout_group_params
      params.require(:workout_group).permit(:name)
    end

end
