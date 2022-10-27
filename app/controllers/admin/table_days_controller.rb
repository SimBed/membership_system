class Admin::TableDaysController < Admin::BaseController
  before_action :set_table_day, only: %i[ show edit update destroy ]

  def index
    @table_days = TableDay.all
  end

  def show
  end

  def new
    @table_day = TableDay.new
  end

  def edit
  end

  def create
    @table_day = TableDay.new(table_day_params)
    if @table_day.save
      redirect_to admin_timetable_path(@table_day.timetable), notice: "Timetable's day was successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @table_day.update(table_day_params)
      redirect_to admin_table_day_path(@table_day), notice: "Timetable's day was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @table_day.destroy
    redirect_to admin_table_days_path, notice: "Timetable's day was successfully deleted."
  end

  private
    def set_table_day
      @table_day = TableDay.find(params[:id])
    end

    def table_day_params
      params.require(:table_day).permit(:name, :short_name, :timetable_id)
    end
end
