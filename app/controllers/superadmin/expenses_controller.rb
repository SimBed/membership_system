class Superadmin::ExpensesController < Superadmin::BaseController
  before_action :set_expense, only: [:show, :edit, :update, :destroy]

  def index
    @expenses = Expense.all
  end

  def show; end

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

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:item, :amount, :date, :workout_group_id)
  end
end
