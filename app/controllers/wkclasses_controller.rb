class WkclassesController < ApplicationController
  before_action :set_wkclass, only: %i[ show edit update destroy ]

  def index
    @wkclasses = Wkclass.order_by_date
  end

  def show
  end

  def new
    @wkclass = Wkclass.new
    # for select in new wkclass form
    @workouts = Workout.all.map { |w| [w.name, w.id] }
  end

  def edit
    @workouts = Workout.all.map { |w| [w.name, w.id] }
  end

  def create
    @wkclass = Wkclass.new(wkclass_params)
      if @wkclass.save
        redirect_to @wkclass, notice: "Class was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
  end

  def update
      if @wkclass.update(wkclass_params)
        redirect_to wkclasses_path, notice: "Class was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
  end

  def destroy
    @wkclass.destroy
    redirect_to wkclasses_url, notice: "Class was successfully deleted."
  end

  private
    def set_wkclass
      @wkclass = Wkclass.find(params[:id])
    end

    def wkclass_params
      params.require(:wkclass).permit(:workout_id, :start_time)
    end
end
