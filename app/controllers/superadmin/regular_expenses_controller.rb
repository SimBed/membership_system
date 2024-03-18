class Superadmin::RegularExpensesController < Superadmin::BaseController
  before_action :set_regular_expense, only: [:edit, :update, :destroy]

  def index
    @regular_expenses = RegularExpense.all.includes(:workout_group)
    @last_month = Time.zone.now.last_month.strftime('%b %Y')
    @this_month = Time.zone.now.strftime('%b %Y')
    @next_month = Time.zone.now.next_month.strftime('%b %Y')
  end

  def new
    @regular_expense = RegularExpense.new
    @workout_groups = WorkoutGroup.all.map { |w| [w.name, w.id] }
  end

  def edit
    @workout_groups = WorkoutGroup.all.map { |w| [w.name, w.id] }
  end

  def create
    @regular_expense = RegularExpense.new(regular_expense_params)
    if @regular_expense.save
      redirect_to superadmin_regular_expenses_path
      flash[:success] = t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @regular_expense.update(regular_expense_params)
      redirect_to superadmin_regular_expenses_path
      flash[:success] = t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @regular_expense.destroy
    redirect_to superadmin_regular_expenses_path
    flash[:success] = t('.success')
  end

  def add
    date = params[:date].to_date
    rejected = 0
    total = RegularExpense.all.size
    RegularExpense.all.each do |r|
      new_expense = Expense.create(
        item: r.item,
        amount: r.amount,
        date:,
        workout_group_id: r.workout_group_id
      )
      rejected += 1 if new_expense.errors.present?
    end
    session[:revenue_month] = date.strftime('%b %Y')
    redirect_to expenses_path
    if rejected.zero?
      flash[:success] = "All #{total} regular expenses added"
    else
      flash[:warning] = "#{total - rejected} of #{total} regular expenses added"
    end
  end

  private

  def set_regular_expense
    @regular_expense = RegularExpense.find(params[:id])
  end

  def regular_expense_params
    params.require(:regular_expense).permit(:item, :amount, :workout_group_id)
  end
end
