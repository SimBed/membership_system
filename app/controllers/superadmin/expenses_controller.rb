class Superadmin::ExpensesController < Superadmin::BaseController
  before_action :set_expense, only: [:edit, :update, :destroy]

  def index
    set_period
    @expenses = Expense.during(@period).order_by_date
    @months = months_logged
  end

  def new
    @expense = Expense.new
    @workout_groups = WorkoutGroup.all.map { |w| [w.name, w.id] }
  end

  def edit
    @workout_groups = WorkoutGroup.all.map { |w| [w.name, w.id] }
    @workout_group = @expense.workout_group.id
  end

  def create
    @expense = Expense.new(expense_params)
    if @expense.save
      redirect_to superadmin_expenses_path
      flash[:success] = t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @expense.update(expense_params)
      redirect_to superadmin_expenses_path
      flash[:success] = t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to superadmin_expenses_path
    flash[:success] = t('.success')
  end

  private

  def set_period
    default_month = Time.zone.today.beginning_of_month.strftime('%b %Y')
    session[:revenue_month] = params[:revenue_month] || session[:revenue_month] || default_month
    @period = month_period(session[:revenue_month])
  end

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:item, :amount, :date, :workout_group_id)
  end

end
