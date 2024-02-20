class Superadmin::PaymentsController < Superadmin::BaseController
  before_action :set_payment, only: [:edit, :update, :destroy]

  def index
    @payments = Payment.order_by_dop
  end

  def show
    @payment = Payment.find(params[:id])
    # payment of restart or payemnt of freeze or payment of purchase
    @purchase = @payment.payable.try(:parent) || @payment.payable.try(:purchase) || @purchase
  end

  def edit
    @payment_methods = Setting.payment_methods
  end

  def update
    if @payment.update(payment_params)
      redirect_to superadmin_payments_path
      flash[:success] = t('.success')
    else
      @payment_methods = Setting.payment_methods
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:amount, :dop, :payment_mode, :note)
  end

end

