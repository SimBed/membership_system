class Superadmin::InstructorRatesController < Superadmin::BaseController
  before_action :set_instructor_rate, only: [:edit, :update, :destroy]

  def index
    @instructor_rates = InstructorRate.order_by_instructor
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
        format.html do
          redirect_to superadmin_instructor_rates_path
          flash[:success] = 'Instructor rate was successfully created.'
        end
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
        format.html do
          redirect_to superadmin_instructor_rates_path
          flash[:success] = 'Instructor rate was successfully updated.'
        end
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
      format.html do
        redirect_to superadmin_instructor_rates_path
        flash[:success] = 'Instructor rate was successfully destroyed.'
      end
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
