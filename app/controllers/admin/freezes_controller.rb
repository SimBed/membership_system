class Admin::FreezesController < Admin::BaseController
  skip_before_action :admin_account
  before_action :junioradmin_account
  before_action :set_freeze, only: [:edit, :update, :destroy]

  def index
    @freezes = Freeze.order_by_start_date_desc
  end

  def new
    start_date = Time.zone.now
    end_date = start_date.advance(days: (14 - 1))
    @freeze = Freeze.new(start_date:, end_date:)
    payment = @freeze.build_payment 
    @payment_methods = Setting.payment_methods
  end
  
  def edit
    @payment_methods = Setting.payment_methods
  end

  def create
    @freeze = Freeze.new(freeze_params)
    if @freeze.save
      @purchase = @freeze.purchase
      redirect_to admin_purchase_path(Purchase.find(freeze_params[:purchase_id]))
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
      redirect_to admin_purchase_path(@purchase)
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
    redirect_to admin_purchase_path(@purchase)
    flash[:success] = t('.success')
    update_purchase_status([@purchase])
  end

  private

  def set_freeze
    @freeze = Freeze.find(params[:id])
  end

  def freeze_params
    params.require(:freeze).permit(:purchase_id, :start_date, :end_date, :note, :medical, :doctor_note, :added_by, payment_attributes: [:dop, :amount, :payment_mode, :note])
  end
end
