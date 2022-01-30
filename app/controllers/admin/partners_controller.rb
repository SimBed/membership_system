class Admin::PartnersController < Admin::BaseController
  skip_before_action :admin_account, only: [:show]
  before_action :correct_account_or_superadmin, only: %i[ show ]
#  before_action :layout_set, only: [:show]
  before_action :set_partner, only: %i[ show edit update destroy ]

  def index
    @partners = Partner.all
  end

  def show
    session[:revenue_period] = params[:revenue_period] || session[:revenue_period] || Date.today.beginning_of_month.strftime('%b %Y')
    start_date = Date.parse(session[:revenue_period])
    end_date = Date.parse(session[:revenue_period]).end_of_month.end_of_day
    @total_share = 0
    @partner_share={}
    @partner.workout_groups.each do |wg|
      attendances = Attendance.by_workout_group(wg.name, start_date, end_date)
      base_revenue = attendances.map { |a| a.revenue }.inject(0, :+)
      expiry_revenue =  wg.expiry_revenue(session[:revenue_period])
      gross_revenue = base_revenue + expiry_revenue
      gst = gross_revenue * (1 - 1 / (1 + wg.gst_rate))
      net_revenue = gross_revenue - gst
      @fixed_expenses = Expense.by_workout_group(wg.name, start_date, end_date)
      total_fixed_expense = @fixed_expenses.map(&:amount).inject(0, :+)
      @wkclasses_with_instructor_expense =
        Wkclass.in_workout_group(wg.name,start_date,end_date)
               .has_instructor_cost
      total_instructor_expense = @wkclasses_with_instructor_expense.map(&:instructor_cost).inject(0, &:+)
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

  def edit
  end

  def create
    @partner = Partner.new(partner_params)

    respond_to do |format|
      if @partner.save
        format.html { redirect_to admin_partners_path
                      flash[:success] = "Partner was successfully created" }
        format.json { render :show, status: :created, location: @partner }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @partner.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @partner.update(partner_params)
        format.html { redirect_to admin_partners_path
                      flash[:success] = "Expense was successfully updated" }
        format.json { render :show, status: :ok, location: @partner }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @partner.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @partner.destroy
    respond_to do |format|
      format.html { redirect_to admin_partners_path
                    flash[:success] = "Expense was successfully updated" }
      format.json { head :no_content }
    end
  end

  private
    def set_partner
      @partner = Partner.find(params[:id])
    end

    def partner_params
      params.require(:partner).permit(:first_name, :last_name, :email, :phone)
    end

    def correct_account_or_superadmin
      redirect_to(root_url) unless Partner.find(params[:id]).account == current_account || logged_in_as_superadmin?
    end

    # def layout_set
    #   if current_account.superadmin?
    #     self.class.layout 'admin'
    #   else
    #     # fails without self.class
    #     self.class.layout 'admin'
    #   end
    # end
end
