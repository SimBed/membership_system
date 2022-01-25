class Superadmin::ExpensesController < Superadmin::BaseController
  before_action :set_expense, only: %i[ show edit update destroy ]

  def index
    @expenses = Expense.all
  end

  def show
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

    respond_to do |format|
      if @expense.save
        format.html { redirect_to superadmin_expenses_path
                      flash[:success] = "Expense was successfully created" }
        format.json { render :show, status: :created, location: @expense }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @expense.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @expense.update(expense_params)
        format.html { redirect_to superadmin_expenses_path
                      flash[:success] = "Expense was successfully updated" }
        format.json { render :show, status: :ok, location: @expense }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @expense.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @expense.destroy
    respond_to do |format|
      format.html { redirect_to superadmin_expenses_path
                    flash[:success] = "Expense was successfully deleted" }
      format.json { head :no_content }
    end
  end

  private
    def set_expense
      @expense = Expense.find(params[:id])
    end

    def expense_params
      params.require(:expense).permit(:item, :amount, :date, :workout_group_id)
    end
end
