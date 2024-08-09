class Admin::FreezesController < Admin::BaseController
  skip_before_action :admin_account
  before_action :junioradmin_account
  before_action :set_freeze, only: [:edit, :update, :destroy]
  
  def index
    @freezes = Freeze.order_by_start_date_desc.includes(:payment, purchase: [:client, product: [:workout_group]])
    @months = ['All'] + months_logged
    handle_period
    handle_pagination    
  end

  def new
    start_date = Time.zone.now
    end_date = start_date.advance(days: (Setting.freeze_duration_days - 1))
    @freeze = Freeze.new(start_date:, end_date:)
    payment = @freeze.build_payment 
    @payment_methods = Setting.payment_methods
  end
  
  def edit
    @payment_methods = Setting.payment_methods
    payment = @freeze.build_payment(amount: 0) if @freeze.payment.nil?
  end

  def create
    @freeze = Freeze.new(freeze_params)
    if @freeze.save
      @purchase = @freeze.purchase
      redirect_to purchase_path(Purchase.find(freeze_params[:purchase_id]))
      flash[:success] = t('.success')
      cancel_bookings_during_freeze(@freeze)
      update_purchase_status([@purchase])
    else
      @payment_methods = Setting.payment_methods
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @freeze.update(freeze_params)
      @purchase = @freeze.purchase
      redirect_to purchase_path(@purchase)
      flash[:success] = t('.success')
      cancel_bookings_during_freeze(@freeze)      
      update_purchase_status([@purchase])
    else
      @payment_methods = Setting.payment_methods
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @purchase = @freeze.purchase
    @freeze.destroy
    redirect_to purchase_path(@purchase)
    flash[:success] = t('.success')
    update_purchase_status([@purchase])
  end

  def filter
    session[:freezes_period] = params[:freezes_period]
    redirect_to freezes_path
  end  

  private

  def handle_period
    if session[:freezes_period].present? && session[:freezes_period] != 'All'
      freezes_paid = @freezes.paid_during(month_period(session[:freezes_period]))
      @freezes_payment_amount_sum = freezes_paid.sum(:amount) if @admin_plus
      freezes_started = @freezes.start_during(month_period(session[:freezes_period]))

      ids = (freezes_paid.pluck(:id) + freezes_started.pluck(:id)).uniq
      @freezes = Freeze.recover_order(ids)
    else
      @freezes_payment_amount_sum = Freeze.joins(:payment).sum(:amount) if @admin_plus
    end
  end
  
  def handle_pagination
    # when exporting data, want it all not just the page of pagination
    if params[:export_all]
      #  @purchases.page(params[:page]).per(100_000)
      @pagy, @freezes = pagy(@freezes, items: 100_000)
    else
      #  @purchases.page params[:page]
      @pagy, @freezes = pagy(@freezes)
    end
  end

  def set_freeze
    @freeze = Freeze.find(params[:id])
  end

  def freeze_params
    params.require(:freeze).permit(:purchase_id, :start_date, :end_date, :note, :medical, :doctor_note, :added_by, payment_attributes: [:dop, :amount, :payment_mode, :note])
  end
end
