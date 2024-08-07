class Admin::RestartsController < Admin::BaseController
  skip_before_action :admin_account
  before_action :junioradmin_account
  before_action :set_restart, only: [:edit, :update, :destroy]
  before_action :set_parent_purchase, only: [:create, :update]

  def new
    @restart = Restart.new
    restart_payment = Purchase.find(params[:purchase_id]).restart_payment
    payment = @restart.build_payment(amount: restart_payment)
    @payment_methods = Setting.payment_methods
  end

  def index
    @restarts = Restart.order_by_dop.includes(:parent, :child)
    # @restarts = Restart.order_by_dop.includes(parent: [:client], child: [:client])
  end

  def edit
    @payment_methods = Setting.payment_methods
  end

  def create
    @restart = Restart.new(restart_params)
    if @restart.save
      # NOTE: update_purchase_status cancels any post expiry bookings (as well as updating the status )
      update_purchase_status([@parent_purchase])
      restart_purchase = @parent_purchase.dup
      # NOTE: update once abstraction fully implemented
      restart_purchase.update(note: nil, status: 'not started', start_date: nil, expiry_date: nil )  
      @restart.update(child_id: restart_purchase.id)
      redirect_to purchase_path(restart_purchase)
      flash[:success] = t('.success')    
    else
      @payment_methods = Setting.payment_methods
      render :new, status: :unprocessable_entity
    end    
  end

  def update
    if @restart.update(restart_params)
      redirect_to purchase_path(@parent_purchase)
      flash[:success] = t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # no delete restarts through UI for now
  # def destroy
  # end

  private

  def set_parent_purchase
    @parent_purchase = Purchase.find(params[:restart][:parent_id]) 
  end

  def set_restart
    @restart = Restart.find(params[:id])
  end

  def restart_params
    params.require(:restart).permit(:parent_id, :added_by, :note, payment_attributes: [:dop, :amount, :payment_mode, :note])
  end
end