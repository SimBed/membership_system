class Superadmin::InstructorRatesController < Superadmin::BaseController
  before_action :set_instructor_rate, only: %i[ show edit update destroy ]

  def index
    @instructor_rates = InstructorRate.all
  end

  def show
  end

  def new
    @instructor_rate = InstructorRate.new
    @instructors = Instructor.all.map { |i| [i.name, i.id] }
  end

  def edit
    @instructors = Instructor.all.map { |i| [i.name, i.id] }
    @instructor = @instructor_rate.instructor.id
  end

  def create
    @instructor_rate = InstructorRate.new(instructor_rate_params)

    respond_to do |format|
      if @instructor_rate.save
        format.html { redirect_to superadmin_instructor_rate_path(@instructor_rate), notice: "Instructor rate was successfully created." }
        format.json { render :show, status: :created, location: @instructor_rate }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @instructor_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @instructor_rate.update(instructor_rate_params)
        format.html { redirect_to superadmin_instructor_rate_path(@instructor_rate), notice: "Instructor rate was successfully updated." }
        format.json { render :show, status: :ok, location: @instructor_rate }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @instructor_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @instructor_rate.destroy
    respond_to do |format|
      format.html { redirect_to superadmin_instructor_rates_path, notice: "Instructor rate was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    def set_instructor_rate
      @instructor_rate = InstructorRate.find(params[:id])
    end

    def instructor_rate_params
      params.require(:instructor_rate).permit(:rate, :date_from, :instructor_id)
    end
end
