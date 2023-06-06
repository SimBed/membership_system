class Superadmin::InstructorRatesController < Superadmin::BaseController
  before_action :set_instructor_rate, only: [:edit, :update, :destroy]

  def index
    @instructor_rates = InstructorRate.order_for_index
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

    if @instructor_rate.save
      redirect_to superadmin_instructor_rates_path
      flash[:success] = t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @instructor_rate.update(instructor_rate_params)
      redirect_to superadmin_instructor_rates_path
      flash[:success] = t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @instructor_rate.destroy
    redirect_to superadmin_instructor_rates_path
    flash[:success] = t('.success')
  end

  private

  def set_instructor_rate
    @instructor_rate = InstructorRate.find(params[:id])
  end

  def instructor_rate_params
    # the update method (and therefore the instructor_rate_params method) is used through a form but also clicking on a link on the instructor_rates page
    return { current: params[:current] } if params[:current].present?

    params.require(:instructor_rate).permit(:rate, :date_from, :instructor_id, :current, :group, :name)
  end
end
