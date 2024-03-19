class Admin::PartnersController < Admin::BaseController
  skip_before_action :admin_account, only: [:show, :edit, :update, :destroy]
  before_action :correct_account_or_superadmin, only: [:show]
  before_action :superadmin_account, only: [:edit, :update, :destroy]
  before_action :set_partner, only: [:show, :edit, :update, :destroy]

  def index
    @partners = Partner.all
  end

  def show
    set_period
    @partner_share = {}
    @partner.workout_groups.each do |wg|
      @partner_share[wg.name.to_sym] = wg.partner_share_amount(@period)
    end
    @total_share = @partner_share.each_value.inject(&:+)
    @months = months_logged
  end

  def new
    @partner = Partner.new
  end

  def edit; end

  def create
    @partner = Partner.new(partner_params)
    if @partner.save
      redirect_to partners_path
      flash[:success] = t('.success')
    else
      format.html { render :new, status: :unprocessable_entity }
    end
  end

  def update
    if @partner.update(partner_params)
      redirect_to partners_path
      flash[:success] = t('.success')
    else
      format.html { render :edit, status: :unprocessable_entity }
    end
  end

  def destroy
    @partner.destroy
    redirect_to partners_path
    flash[:success] = t('.success')
  end

  private

  def set_period
    default_month = Time.zone.today.beginning_of_month.strftime('%b %Y')
    session[:revenue_month] = params[:revenue_month] || session[:revenue_month] || default_month
    @period = month_period(session[:revenue_month])
  end

  def set_partner
    @partner = Partner.find(params[:id])
  end

  def partner_params
    params.require(:partner).permit(:first_name, :last_name, :email, :phone, :whatsapp, :instagram)
  end

  def correct_account_or_superadmin
    redirect_to login_path unless Partner.find(params[:id]).account == current_account || logged_in_as?('superadmin')
  end

  def superadmin_account
    redirect_to login_path unless logged_in_as?('superadmin')
  end
end
