class Admin::PartnersController < Admin::BaseController
  skip_before_action :admin_account, only: [:show, :edit, :update, :destroy]
  before_action :correct_account_or_superadmin, only: [:show]
  before_action :superadmin_account, only: [:edit, :update, :destroy]
  before_action :set_partner, only: [:show, :edit, :update, :destroy]

  def index
    @partners = Partner.all
  end

  def show
    set_date_period
    @total_share = 0
    @partner_share = {}
    @partner.workout_groups.each do |wg|
      attendances_in_period = Attendance.confirmed.by_workout_group(wg.name, @start_date, @end_date)
      base_revenue = attendances_in_period.map(&:revenue).inject(0, :+)
      expiry_revenue = wg.expiry_revenue(session[:revenue_period])
      gross_revenue = base_revenue + expiry_revenue
      gst = gross_revenue * (1 - (1 / (1 + wg.gst_rate)))
      net_revenue = gross_revenue - gst
      @fixed_expenses = Expense.by_workout_group(wg.name, @start_date, @end_date)
      total_fixed_expense = @fixed_expenses.sum(:amount)
      total_instructor_expense =
        Wkclass.in_workout_group(wg.name)
               .between(@start_date, @end_date)
               .has_instructor_cost
               .sum(:instructor_cost)
      total_expense = total_fixed_expense + total_instructor_expense
      profit = net_revenue - total_expense
      partner_share = profit * wg.partner_share.to_f / 100
      @partner_share[wg.name.to_sym] = partner_share
      @total_share += partner_share
    end
    @months = months_logged
  end

  def new
    @partner = Partner.new
  end

  def edit; end

  def create
    @partner = Partner.new(partner_params)
    if @partner.save
      redirect_to admin_partners_path
      flash[:success] = t('.success')
    else
      format.html { render :new, status: :unprocessable_entity }
    end
  end

  def update
    if @partner.update(partner_params)
      redirect_to admin_partners_path
      flash[:success] = t('.success')
    else
      format.html { render :edit, status: :unprocessable_entity }
    end
  end

  def destroy
    @partner.destroy
    redirect_to admin_partners_path
    flash[:success] = t('.success')
  end

  private

  def set_date_period
    session[:revenue_period] =
      params[:revenue_period] || session[:revenue_period] || Time.zone.today.beginning_of_month.strftime('%b %Y')
    @start_date = Date.parse(session[:revenue_period])
    @end_date = Date.parse(session[:revenue_period]).end_of_month.end_of_day
  end

  def set_partner
    @partner = Partner.find(params[:id])
  end

  def partner_params
    params.require(:partner).permit(:first_name, :last_name, :email, :phone)
  end

  def correct_account_or_superadmin
    redirect_to login_path unless Partner.find(params[:id]).account == current_account || logged_in_as?('superadmin')
  end

  def superadmin_account
    redirect_to login_path unless logged_in_as?('superadmin')
  end
end
