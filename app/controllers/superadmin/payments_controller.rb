class Superadmin::PaymentsController < Superadmin::BaseController
  before_action :initialize_sort, only: :index
  before_action :set_payment, only: [:edit, :update, :destroy]
  before_action :set_admin_status, only: [:index]  

  def index
    @payments = Payment.order_by_dop
    handle_filter
    handle_period
    @payments_amount_sum = @payments.sum(:amount)
    handle_sort
    prepare_items_for_filters
    handle_pagination
    # handle_index_response 
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

  def filter
    clear_session(*session_filter_list)
    session[:payments_period] = params[:payments_period]
    (params_filter_list - [:payments_period]).each do |item|
      session["filter_#{item}".to_sym] = params[item]
    end
    redirect_to superadmin_payments_path
  end  

  private

    def initialize_sort
      session[:sort_option] = params[:sort_option] || session[:sort_option] || 'dop'
    end

    def handle_filter
      %w[payable_types].each do |key|
        @payments = @payments.send(key, session["filter_#{key}"]) if session["filter_#{key}"].present?
      end
    end

    def handle_period
      return unless session[:payments_period].present? && session[:payments_period] != 'All'

      @payments = @payments.during(month_period(session[:payments_period]))
    end

    def prepare_items_for_filters
      @payable_types = Payment.distinct.pluck(:payable_type).sort!
      @months = ['All'] + months_logged
    end
  
    def handle_sort
      case session[:sort_option]
      when 'dop'
        sort_on_database
      when 'client_name'
        sort_on_object
      end
    end
  
    def sort_on_database
      @payments = @payments.send("order_by_#{session[:sort_option]}")
    end
  
    def sort_on_object
      @payments = @payments.to_a.sort_by do |p|
        case p.payable_type
        when 'Freeze'
          p.payable.purchase.client.first_name
        when 'Restart'
          p.payable.parent.client.first_name
        when 'Purchase' 
          p.payable.client.first_name
        end
      end
      ids = @payments.map(&:id)
      @payments = Payment.recover_order(ids)
    end
  
    def params_filter_list
      [:payable_types, :payments_period]
    end
  
    def session_filter_list
      params_filter_list.map { |i| "filter_#{i}" }
    end
    
    def handle_pagination
      # when exporting data, want it all not just the page of pagination
      if params[:export_all]
        #  @purchases.page(params[:page]).per(100_000)
        @pagy, @payments = pagy(@payments, items: 100_000)
      else
        #  @purchases.page params[:page]
        @pagy, @payments = pagy(@payments, item: 100)
      end
    end
      
    def set_admin_status
      @superadmin_plus = logged_in_as?('superadmin')
    end

    def set_payment
      @payment = Payment.find(params[:id])
    end

    def payment_params
      params.require(:payment).permit(:amount, :dop, :payment_mode, :note)
    end

end

