class Superadmin::InstructorSalariesController < Superadmin::BaseController
  before_action :set_instructor_salary, only: %i[ show edit update destroy ]

  def index
    @instructor_salaries = InstructorSalary.all
  end

  def show
  end

  def new
    @instructor_salary = InstructorSalary.new
  end

  def edit
  end

  def create
    @instructor_salary = InstructorSalary.new(instructor_salary_params)

    respond_to do |format|
      if @instructor_salary.save
        format.html { redirect_to superadmin_instructor_salary_path(@instructor_salary), notice: "Instructor salary was successfully created." }
        format.json { render :show, status: :created, location: @instructor_salary }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @instructor_salary.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @instructor_salary.update(instructor_salary_params)
        format.html { redirect_to superadmin_instructor_salary_path(@instructor_salary), notice: "Instructor salary was successfully updated." }
        format.json { render :show, status: :ok, location: @instructor_salary }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @instructor_salary.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /instructor_salaries/1 or /instructor_salaries/1.json
  def destroy
    @instructor_salary.destroy
    respond_to do |format|
      format.html { redirect_to superadmin_instructor_salaries_path, notice: "Instructor salary was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_instructor_salary
      @instructor_salary = InstructorSalary.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def instructor_salary_params
      params.require(:instructor_salary).permit(:salary, :date_from, :instructor_id)
    end
end
