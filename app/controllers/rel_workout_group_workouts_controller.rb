class RelWorkoutGroupWorkoutsController < ApplicationController
  before_action :set_rel_workout_group_workout, only: %i[ show edit update destroy ]

  # GET /rel_workout_group_workouts or /rel_workout_group_workouts.json
  def index
    @rel_workout_group_workouts = RelWorkoutGroupWorkout.all
  end

  # GET /rel_workout_group_workouts/1 or /rel_workout_group_workouts/1.json
  def show
  end

  # GET /rel_workout_group_workouts/new
  def new
    @rel_workout_group_workout = RelWorkoutGroupWorkout.new
  end

  # GET /rel_workout_group_workouts/1/edit
  def edit
  end

  # POST /rel_workout_group_workouts or /rel_workout_group_workouts.json
  def create
    @rel_workout_group_workout = RelWorkoutGroupWorkout.new(rel_workout_group_workout_params)

    respond_to do |format|
      if @rel_workout_group_workout.save
        format.html { redirect_to @rel_workout_group_workout, notice: "Rel workout group workout was successfully created." }
        format.json { render :show, status: :created, location: @rel_workout_group_workout }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @rel_workout_group_workout.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rel_workout_group_workouts/1 or /rel_workout_group_workouts/1.json
  def update
    respond_to do |format|
      if @rel_workout_group_workout.update(rel_workout_group_workout_params)
        format.html { redirect_to @rel_workout_group_workout, notice: "Rel workout group workout was successfully updated." }
        format.json { render :show, status: :ok, location: @rel_workout_group_workout }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @rel_workout_group_workout.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rel_workout_group_workouts/1 or /rel_workout_group_workouts/1.json
  def destroy
    @rel_workout_group_workout.destroy
    respond_to do |format|
      format.html { redirect_to rel_workout_group_workouts_url, notice: "Rel workout group workout was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rel_workout_group_workout
      @rel_workout_group_workout = RelWorkoutGroupWorkout.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def rel_workout_group_workout_params
      params.require(:rel_workout_group_workout).permit(:workout_group_id, :workout_ids)
    end
end
