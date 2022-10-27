class Admin::TimetablesController < Admin::BaseController
  before_action :set_timetable, only: %i[ show edit update destroy ]

  def index
    @timetables = Timetable.all
  end

  def show
    #build a #entries hash to avoid database lookups in the view
    render layout: "timetable"
  end

  def new
    @timetable = Timetable.new
  end

  def edit
  end

  def create
    @timetable = Timetable.new(timetable_params)
    if @timetable.save
      flash_message :success, "Timetable was successfully created."
      redirect_to admin_timetable_path(@timetable)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @timetable.update(timetable_params)
      redirect_to admin_timetable_path(@timetable), notice: "Timetable was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @timetable.destroy
    redirect_to admin_timetables_path, notice: "Timetable was successfully deleted."
  end

  private
    def set_timetable
      @timetable = Timetable.find(params[:id])
    end

    def timetable_params
      params.require(:timetable).permit(:title)
    end
end
