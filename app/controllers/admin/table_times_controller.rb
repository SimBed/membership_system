class Admin::TableTimesController < Admin::BaseController
  before_action :set_table_time, only: [:show, :edit, :update, :destroy]
  before_action :set_timetable, only: [:update, :destroy]

  def index
    @table_times = TableTime.all
  end

  def new
    @table_time = TableTime.new
  end

  def edit; end

  def create
    @table_time = TableTime.new(table_time_params)
    if @table_time.save
      flash_message :success, "Timetable's time was successfully added"
      redirect_to admin_timetable_path(@table_time.timetable)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @table_time.update(table_time_params)
      flash_message :success, "Timetable's time was successfully updated"
      redirect_to admin_timetable_path(@timetable)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @table_time.destroy
    flash_message :success, "Timetable's time was successfully deleted"
    redirect_to admin_timetable_path(@timetable)
  end

  private

  def set_table_time
    @table_time = TableTime.find(params[:id])
  end

  def set_timetable
    @timetable = @table_time.timetable
  end

  def table_time_params
    params.require(:table_time).permit(:start, :timetable_id)
  end
end
