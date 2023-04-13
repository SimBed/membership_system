class Admin::InstructorsController < Admin::BaseController
  skip_before_action :admin_account, only: [:show]
  before_action :set_instructor, only: [:show, :edit, :update, :destroy]
  before_action :correct_instructor, only: [:show]
  before_action :set_raw_numbers, only: :edit  

  def index
    @instructors = Instructor.order_by_current.order_by_name
  end

  def show
    set_period
    @wkclasses = Wkclass.during(@period).with_instructor(@instructor.id)
    @wkclasses_with_instructor_expense = @wkclasses.has_instructor_cost.includes(:workout, :instructor)
    @months = months_logged       
  end

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

  def set_period
    default_month = Time.zone.today.beginning_of_month.strftime('%b %Y')
    session[:revenue_month] = params[:revenue_month] || session[:revenue_month] || default_month
    session[:revenue_month] = default_month if session[:revenue_month] == 'All'
    @period = month_period(session[:revenue_month])
  end  
  
  def set_instructor
    @instructor = Instructor.find(params[:id])
  end
  
  def correct_instructor
    redirect_to login_path unless current_account?(@instructor.account)
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
