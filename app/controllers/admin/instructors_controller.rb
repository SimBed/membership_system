class Admin::InstructorsController < Admin::BaseController
  before_action :set_instructor, only: [:show, :edit, :update, :destroy]
  before_action :set_raw_numbers, only: :edit  

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

  def set_raw_numbers
    @instructor.whatsapp_country_code = @instructor.country(:whatsapp)
    @instructor.whatsapp_raw = @instructor.number_raw(:whatsapp) 
  end    

  def instructor_params
    # the update method (and therefore the instructor_params method) is used through a form but also clicking on a link on the instructors page
    return {current: params[:current] } if params[:current].present?    

    params.require(:instructor).permit(:first_name, :last_name, :email, :whatsapp_country_code, :whatsapp_raw, :current)
  end
end
