class Admin::InstructorsController < Admin::BaseController
  before_action :set_instructor, only: [:show, :edit, :update, :destroy]

  def index
    @instructors = Instructor.order_by_current.order_by_name
  end

  def show; end

  def new
    @instructor = Instructor.new
  end

  def edit; end

  def create
    @instructor = Instructor.new(instructor_params)

    if @instructor.save
      redirect_to admin_instructors_path
      flash[:success] = t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @instructor.update(instructor_params)
      redirect_to admin_instructors_path
      flash[:success] = t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @instructor.destroy
    redirect_to admin_instructors_path
    flash[:success] = t('.success')
  end

  private

  def set_instructor
    @instructor = Instructor.find(params[:id])
  end

  def instructor_params
    params.require(:instructor).permit(:first_name, :last_name, :current)
  end
end
