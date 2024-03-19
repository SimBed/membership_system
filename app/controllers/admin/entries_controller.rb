class Admin::EntriesController < Admin::BaseController
  before_action :set_entry, only: [:show, :edit, :update, :destroy]

  def index
    @entries = Entry.all
  end

  def new
    @entry = Entry.new
    prepare_items_for_dropdowns
  end

  def edit
    prepare_items_for_dropdowns
  end

  def create
    @entry = Entry.new(entry_params)
    if @entry.save
      flash_message :success, 'Entry was successfully added.'
      redirect_to timetable_path(@entry.table_time.timetable)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @entry.update(entry_params)
      flash_message :success, 'Entry was successfully updated.'
      redirect_to timetable_path(@entry.table_time.timetable)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    timetable = @entry.table_time.timetable
    @entry.destroy
    redirect_to timetable_path(timetable), notice: 'Entry was successfully deleted.'
  end

  private

  def set_entry
    @entry = Entry.find(params[:id])
  end

  def entry_params
    params.require(:entry).permit(:goal, :level, :studio, :duration, :workout_id, :table_time_id, :table_day_id)
  end

  def prepare_items_for_dropdowns
    @workouts = Workout.current.order_by_name
    @levels = Setting.levels
    @studios = Setting.studios
    @goals = Setting.goals
    @durations = Setting.durations
  end
end
