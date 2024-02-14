class Superadmin::PaymentsController < Superadmin::BaseController
  def index
    @payments = Payment.all
  end
end
