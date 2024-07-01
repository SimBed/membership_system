class Admin::WorkoutGroupsController < Admin::BaseController
  skip_before_action :admin_account, only: [:show, :instructor_expense_filter]
  before_action :superadmin_account, only: [:show, :instructor_expense_filter]
  before_action :set_workout_group, only: [:show, :edit, :update, :destroy, :show_workouts, :toggle_current, :instructor_expense_filter]

  def index
    @workout_groups = WorkoutGroup.order_by_current
    handle_index_response
  end

  def show
    set_period
    @wkclasses = @workout_group.wkclasses_during(@period)
    # @wkclasses_with_instructor_expense = @wkclasses.has_instructor_cost.includes(:workout, :instructor)
    @wkclasses_with_instructor_expense = @wkclasses.has_instructor_cost.includes(:workout, :instructor)
    set_instructor_filters
    @wkclasses_with_instructor_expense = @wkclasses_with_instructor_expense.send(:with_instructor, session[:filter_instructor]) if session[:filter_instructor].present?
    # unscope :order from wkclasses_during method otherwise get an ActiveRecord::StatementInvalid Exception: PG::GroupingError: ERROR
    # @instructor_cost_subtotals = @wkclasses_with_instructor_expense.unscope(:order).group_by_instructor_cost.delete_if { |k, v| v.zero? }
    # @instructor_cost_counts = @wkclasses_with_instructor_expense.unscope(:order).joins(:instructor).group("first_name || ' ' || last_name").count(:instructor_cost).delete_if { |k, v| v.zero? }
    # ugly way to get aggregate functions together with the grouping itself
    # https://stackoverflow.com/questions/27145994/rails-activerecord-perform-group-sum-and-count-in-one-query
    @instructor_cost_subtotals = @wkclasses_with_instructor_expense.unscope(:order).joins(:instructor).group("first_name || ' ' || last_name").pluck('max(first_name), max(last_name), sum(instructor_cost), count(instructor_cost)')
    @total_instructor_cost = @instructor_cost_subtotals.pluck(2).compact.sum
    @fixed_expenses = Expense.by_workout_group(@workout_group.name, @period)
    @months = months_logged
    @summary = {}
    set_revenue_summary
    set_expense_summary

    # @instructor_filter_options = Instructor.current.has_rate.order_by_name
  end

  def new
    @workout_group = WorkoutGroup.new
    prepare_items_for_dropdowns
    @form_cancel_link = workout_groups_path
  end

  def edit
    prepare_items_for_dropdowns
    @form_cancel_link = workout_groups_path
  end

  def create
    # @workout_group = WorkoutGroup.new(name: params[:workout_group][:name], workout_ids: params[:workout_ids])
    @workout_group = WorkoutGroup.new(workout_group_params)
    if @workout_group.save
      redirect_to workout_groups_path
      flash[:success] = t('.success')
    else
      prepare_items_for_dropdowns
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @workout_group.update(workout_group_params)
      redirect_to workout_groups_path
      flash[:success] = t('.success')
    else
      prepare_items_for_dropdowns
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workout_group.destroy
    redirect_to workout_groups_path
    flash[:success] = t('.success')
  end

  def toggle_current
    @workout_group.update_column(:current, workout_group_params[:current])
    redirect_to workout_groups_path
  end

  def instructor_expense_filter
    clear_session(:filter_instructor)
    session[:filter_instructor] = params[:instructor]
    # redirect_to "/workout_groups/#{params[:id]}"
    redirect_to @workout_group
  end

  def show_workouts
    @current_workouts = @workout_group.workouts.current.order_by_name
    @not_current_workouts = @workout_group.workouts.not_current.order_by_name
  end

  private

  def prepare_items_for_dropdowns
    @workouts = Workout.order_by_current
    @services = Rails.application.config_for(:constants)['workout_group_services']
  end

  def set_instructor_filters
    # @wkclasses_with_instructor_expense.pluck('distinct wkclasses.instructor_id') runs into ambiguous coulmn error because instructor_id in wkclass and in instructor_rate
    # @wkclasses_with_instructor_expense.pluck('distinct wkclasses.instructor_id') gives an ActiveRecord::UnknownAttributeReference error
    # https://stackoverflow.com/questions/49890531/rails-select-distinct-association-from-collection
    @instructor_filter_options = Instructor.where(id: Wkclass.where(id: @wkclasses_with_instructor_expense.map(&:id)).pluck('distinct instructor_id'))
  end

  # def set_period
  #   default_month = Time.zone.today.beginning_of_month.strftime('%b %Y')
  #   session[:revenue_month] = params[:revenue_month] || session[:revenue_month] || default_month
  #   session[:revenue_month] = default_month if session[:revenue_month] == 'All'
  #   @period = month_period(session[:revenue_month])
  # end

  # became more complicated when hotwired workout_group show as multiple workout groups can be shown at the same time with different periods
  def set_period
    workout_group = "workout_group_#{@workout_group.id}".to_sym
    session[workout_group] = {} if session[workout_group].nil?
    default_month = Time.zone.today.beginning_of_month.strftime('%b %Y')
    # must be session[workout_group]['revenue_month'] not session[workout_group][:revenue_month]
    session[workout_group][:revenue_month] = params[:revenue_month] || session[workout_group]['revenue_month'] || default_month
    session[workout_group][:revenue_month] = default_month if session[workout_group][:revenue_month] == 'All'
    @period = month_period(session[workout_group][:revenue_month])
    @revenue_month = session[workout_group][:revenue_month]
  end

  def set_revenue_summary
    revenue_params = {
      attendance_count: @workout_group.attendances_during(@period).size,
      wkclass_count: @wkclasses.size,
      membership_revenue: @workout_group.revenue('Purchase', @period),
      freeze_revenue: @workout_group.revenue('Freeze', @period),
      restart_revenue: @workout_group.revenue('Restart', @period),
      total_revenue: @workout_group.revenue('all', @period)
    }
    @summary.merge!(revenue_params)
  end

  def set_expense_summary
    expense_params = {
      instructor_expense: @workout_group.instructor_expense(@period),
      variable_expense_filtered: @wkclasses_with_instructor_expense.sum(:instructor_cost),
      net_revenue: @workout_group.net_revenue(@period)
    }
    @summary.merge!(expense_params)
  end

  def handle_index_response
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def set_workout_group
    @workout_group = WorkoutGroup.find(params[:id])
  end

  def workout_group_params
    # the update method (and therefore the workout_group_params method) is used through a form but also by clicking on a link on the workout_groups page
    return { current: params[:current] } if params[:current].present?
    
    params.require(:workout_group).permit(:name, :service, :requires_account, :current, workout_ids: [])
  end

end
