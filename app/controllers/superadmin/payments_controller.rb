class Superadmin::PaymentsController < Superadmin::BaseController
  def index
    @payments = Payment.all
  end

  def show
    @payment = Payment.find(params[:id])
  end
end
