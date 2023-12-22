class Admin::TableDaysController < Admin::BaseController
  before_action :set_table_day, only: [:show, :edit, :update, :destroy]
  before_action :set_timetable, only: [:update, :destroy]

  def index
    @table_days = TableDay.all
  end

  def new
    @table_day = TableDay.new
  end

  def edit; end

  def create
    @table_day = TableDay.new(table_day_params)
    if @table_day.save
      flash_message :success, "Timetable's day was successfully added"
      redirect_to admin_timetable_path(@table_day.timetable)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @table_day.update(table_day_params)
      flash_message :success, "Timetable's day was successfully updated"
      redirect_to admin_timetable_path(@timetable)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @table_day.destroy
    flash_message :success, "Timetable's day was successfully deleted"
    redirect_to admin_timetable_path(@timetable)
  end

  private

  def set_table_day
    @table_day = TableDay.find(params[:id])
  end

  def set_timetable
    @timetable = @table_day.timetable
  end

  def table_day_params
    params.require(:table_day).permit(:name, :short_name, :timetable_id)
  end
end
