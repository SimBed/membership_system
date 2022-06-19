class Admin::WorkoutGroupsController < Admin::BaseController
  skip_before_action :admin_account, only: [:show, :index]
  before_action :partner_or_admin_account, only: [:index]
  before_action :correct_account_or_superadmin, only: [:show]
  before_action :set_workout_group, only: [:show, :edit, :update, :destroy]

  def index
    if logged_in_as?('partner')
      partner_id = current_account.partners.first.id
      # reformat to scope
      @workout_groups = WorkoutGroup.where(partner_id: partner_id).order_by_name
    else
      @workout_groups = WorkoutGroup.order_by_name
    end
  end

  def show
    set_period
    @wkclasses = @workout_group.wkclasses_during(@period)
    @wkclasses_with_instructor_expense = @wkclasses.has_instructor_cost
    @fixed_expenses = Expense.by_workout_group(@workout_group.name, @period)
    @months = months_logged
    @summary = {}
    set_revenue_summary
    set_expense_summary
  end

  def new
    @workout_group = WorkoutGroup.new
    @workouts = Workout.all
    @partners = Partner.all.map { |p| [p.first_name, p.id] }
  end

  def edit
    @workouts = Workout.all
    @partners = Partner.all.map { |p| [p.first_name, p.id] }
    @partner = @workout_group.partner
  end

  def create
    # @workout_group = WorkoutGroup.new(name: params[:workout_group][:name], workout_ids: params[:workout_ids])
    @workout_group = WorkoutGroup.new(workout_group_params)
    if @workout_group.save
      redirect_to admin_workout_groups_path
      flash[:success] = t('.success')
    else
      @workouts = Workout.all
      @partners = Partner.all.map { |p| [p.first_name, p.id] }
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @workout_group.update(workout_group_params)
      redirect_to admin_workout_groups_path
      flash[:success] = t('.success')
    else
      @workouts = Workout.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workout_group.destroy
    redirect_to admin_workout_groups_path
    flash[:success] = t('.success')
  end

  private

  def set_period
    default_month = Time.zone.today.beginning_of_month.strftime('%b %Y')
    session[:revenue_month] = params[:revenue_month] || session[:revenue_month] || default_month
    session[:revenue_month] = default_month if session[:revenue_month] == 'All'
    @period = month_period(session[:revenue_month])
  end

  def set_revenue_summary
    revenue_params = {
      attendance_count: @workout_group.attendances_during(@period).size,
      wkclass_count: @wkclasses.size,
      base_revenue: @workout_group.base_revenue(@period),
      expiry_revenue: @workout_group.expiry_revenue(@period),
      gross_revenue: @workout_group.gross_revenue(@period),
      gst: @workout_group.gst(@period),
      net_revenue: @workout_group.net_revenue(@period)
    }
    @summary.merge!(revenue_params)
  end

  def set_expense_summary
    expense_params = {
      fixed_expense: @workout_group.fixed_expense(@period),
      variable_expense: @workout_group.variable_expense(@period),
      total_expense: @workout_group.total_expense(@period),
      profit: @workout_group.profit(@period),
      partner_share: @workout_group.partner_share_amount(@period)
    }
    @summary.merge!(expense_params)
  end

  def set_workout_group
    @workout_group = WorkoutGroup.find(params[:id])
  end

  def workout_group_params
    params.require(:workout_group).permit(:name, :partner_id, :partner_share, :gst_applies, :requires_invoice,
                                          workout_ids: [])
  end

  def correct_account_or_superadmin
    return if WorkoutGroup.find(params[:id]).partner.account == current_account || logged_in_as?('superadmin')

    redirect_to login_path
  end

  def partner_or_superadmin_account
    return if logged_in_as?('superadmin') || logged_in_as?('partner')

    redirect_to login_path
  end

  def partner_or_admin_account
    return if logged_in_as?('admin', 'superadmin') || logged_in_as?('partner')

    redirect_to login_path
    flash[:warning] = I18n.t(:forbidden)
  end
end
