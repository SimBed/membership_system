class Admin::InstructorsController < Admin::BaseController
  skip_before_action :admin_account, only: :show
  before_action :set_instructor, only: [:show, :edit, :update, :destroy]
  before_action :correct_instructor_or_superadmin, only: :show
  before_action :initialize_sort, only: :show
  before_action :set_raw_numbers, only: :edit

  def index
    @current_instructors = Instructor.current.order_by_name
    @not_current_instructors = Instructor.not_current.order_by_name
    @superadmin = logged_in_as?('superadmin') ? true : false  
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    set_period
    @wkclasses = Wkclass.during(@period).with_instructor(@instructor.id)
    @wkclasses_with_instructor_expense = @wkclasses.unscope(:order).has_instructor_cost.includes(:workout, :attendances, instructor: [:instructor_rates])
    @wkclasses_with_no_instructor_expense = @wkclasses.unscope(:order).has_no_instructor_cost.includes(:workout, :attendances, instructor: [:instructor_rates])
    # this double counts and I cant find a way to prevent it (tried with distinct and group) so fallen back on ruby object
    # @total_instructor_cost_for_period = @wkclasses_with_instructor_expense.sum(:rate)
    @total_instructor_cost_for_period = @wkclasses_with_instructor_expense.map(&:rate).inject(0, :+)
    handle_sort
    @months = months_logged
    @show_classes_with_no_expense = logged_in_as?('superadmin') ? true : false
  end

  def new
    @instructor = Instructor.new
  end

  def edit; end

  def create
    @instructor = Instructor.new(instructor_params)

    if @instructor.save
      redirect_to instructors_path
      flash[:success] = t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @instructor.update(instructor_params)
      redirect_to instructors_path
      flash[:success] = t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @instructor.destroy
    redirect_to instructors_path
    flash[:success] = t('.success')
  end

  private

  def initialize_sort
    session[:instructor_expense_sort_option] = params[:instructor_expense_sort_option] || session[:instructor_expense_sort_option] || 'wkclass_date'
  end

  def handle_sort
    case session[:instructor_expense_sort_option]
    when 'wkclass_date'
      @wkclasses_with_instructor_expense = @wkclasses_with_instructor_expense.order_by_date
      @wkclasses_with_no_instructor_expense = @wkclasses_with_no_instructor_expense.order_by_date
    when 'client_name'
      sort_on_object
    end
  end

  def sort_on_object
    @wkclasses_with_instructor_expense = @wkclasses_with_instructor_expense.to_a.sort_by do |w|
      # this seems to be the way to use sort_by with a secondary order (but fails when attendance is nil for some reason "|| 'Z'" mitigates this)
      [w.attendances&.first&.client&.name || 'Z', -w.start_time.to_i]
    end
    @wkclasses_with_no_instructor_expense = @wkclasses_with_no_instructor_expense.to_a.sort_by do |w|
      [w.attendances&.first&.client&.name || 'Z', -w.start_time.to_i]
    end
  end

  def set_period
    default_month = Time.zone.today.beginning_of_month.strftime('%b %Y')
    session[:revenue_month] = params[:revenue_month] || session[:revenue_month] || default_month
    session[:revenue_month] = default_month if session[:revenue_month] == 'All'
    @period = month_period(session[:revenue_month])
  end

  def set_instructor
    @instructor = Instructor.find(params[:id])
  end

  def correct_instructor_or_superadmin
    return if logged_in_as?('superadmin')

    redirect_to login_path unless current_account?(@instructor.account)
  end

  def set_raw_numbers
    @instructor.whatsapp_country_code = @instructor.country(:whatsapp)
    @instructor.whatsapp_raw = @instructor.number_raw(:whatsapp)
  end

  def instructor_params
    # the update method (and therefore the instructor_params method) is used through a form but also clicking on a link on the instructors page
    return { current: params[:current] } if params[:current].present?

    return { commission: params[:commission] } if params[:commission].present?
    
    return { employee: params[:employee] } if params[:employee].present?

    params.require(:instructor).permit(:first_name, :last_name, :email, :whatsapp_country_code, :whatsapp_raw, :current, :commission, :employee)
  end
end
