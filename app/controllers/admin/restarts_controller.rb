class Admin::RestartsController < Admin::BaseController
  skip_before_action :admin_account
  before_action :junioradmin_account
  before_action :set_restart, only: [:edit, :update, :destroy]

  def new
    @restart = Restart.new
    restart_payment = Purchase.find(params[:purchase_id]).restart_payment
    payment = @restart.build_payment(amount: restart_payment)
    @payment_methods = Setting.payment_methods
  end

  def index
    @restarts = Restart.order_by_dop.includes(:payment) 
  end

  def edit
  end

  def create
    @restart = Restart.new(restart_params)
    if @restart.save
      @purchase = @restart.purchase
      # NOTE: update_purchase_status also cancels any post expiry bookings
      update_purchase_status([@purchase])
      new_purchase = @purchase.dup
      new_purchase.update(adjust_restart: false, ar_payment: 0, status: 'not started' )
      redirect_to admin_purchase_path(@purchase)
      flash[:success] = t('.success')    
    else
      @payment_methods = Setting.payment_methods
      render :new, status: :unprocessable_entity
    end    

  end

  def update
  end

  def destroy
  end

  private

  def set_restart
    @restart = Restart.find(params[:id])
  end

  def restart_params
    params.require(:restart).permit(:purchase_id, :added_by, :note, payment_attributes: [:dop, :amount, :payment_mode, :note])
  end

  # taken from purchases_controller
  def adjust_and_restart
    new_purchase = @purchase.dup
    new_purchase.update(adjust_restart: false, ar_payment: 0, status: 'not started' )
    flash_message :warning, t('.adjust_and_restart')
    redirect_to admin_purchases_path
  end
end