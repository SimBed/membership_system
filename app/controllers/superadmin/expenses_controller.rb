class Superadmin::ExpensesController < Superadmin::BaseController
  before_action :set_expense, only: [:edit, :update, :destroy]

  def index
    @expenses = Expense.order_by_date
    @months = ['All'] + months_logged
    handle_period unless params[:export_all]
    respond_to do |format|
      format.html
      format.csv { send_data @expenses.to_csv }
    end
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

  def filter
    session[:revenue_month] = params[:revenue_month]
    redirect_to superadmin_expenses_path
  end

  private

  def handle_period
    return unless session[:revenue_month].present? && session[:revenue_month] != 'All'

    default_month = Time.zone.today.beginning_of_month.strftime('%b %Y')
    session[:revenue_month] = params[:revenue_month] || session[:revenue_month] || default_month
    @expenses = @expenses.during(month_period(session[:revenue_month]))
  end

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:item, :amount, :date, :workout_group_id)
  end
end
