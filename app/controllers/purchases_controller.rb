require 'byebug'
class PurchasesController < ApplicationController
  before_action :initialize_sort, only: :index
  before_action :set_purchase, only: %i[ show edit update destroy ]

  def index
    # obsolete now - optimised by sorting at databse
    # convoluted but seems ok way to sort by date descending when date is part of a multiple parameter sort
    #@purchases = Purchase.all.sort_by { |p| [p.client.name, -p.dop&.to_time.to_i] }
    @purchases = Purchase.all
    handle_search
    #@problems = @problems.send("order_by_#{session[:sort_option]}").paginate(page: params[:page], per_page: 10)
    @workout_group = WorkoutGroup.distinct.pluck(:name).sort!
    @status = %w[expired frozen not\ started ongoing]
    case session[:sort_option]
    when 'client_dop', 'dop'
      @purchases = @purchases.send("order_by_#{session[:sort_option]}") #.paginate(page: params[:page], per_page: 30)
    when 'expiry'
      @purchases = @purchases.to_a.sort_by { |p| p.days_to_expiry } #.paginate(page: params[:page], per_page: 30)
    when 'classes_remain'
      @purchases = @purchases.to_a.sort_by { |p| p.attendances_remain_numeric }
    end

    # it is not critical that expired purchases are identifiable at database level. This will just improve efficiency as the number of purchases gets biggger over time.
    # For example, the form for adding a new attendance makes qualifying purchases available from a select box. It is inefficient
    # to have to run ruby code on the entire population of purchases to identify the non-expired purchases.
    # There are probably more appropriate ways of updating the purchase's status at database level, but running some code
    # here is inoccuous (negligibly slows down a non-speed-critical page) and means the database will be kept up to data intermittently which achieves the aim.
    expire_purchases
  end

  def show
    @attendances = @purchase.attendances.sort_by { |a| -a.start_time.to_i }
  end

  def new
    @purchase = Purchase.new
    @clients = Client.order_by_name.map { |c| [c.name, c.id] }
    @products = Product.all.map { |p| [p.name, p.id] }
    @payment_methods = Rails.application.config_for(:constants)["payment_methods"]
  end

  def edit
    @clients = Client.order_by_name.map { |c| [c.name, c.id] }
    @products = Product.all.map { |p| [p.name, p.id] }
    @payment_methods = Rails.application.config_for(:constants)["payment_methods"]
  end

  def create
    @purchase = Purchase.new(purchase_params)
      if @purchase.save
        redirect_to @purchase
        flash[:success] = "Purchase was successfully created"
      else
        @clients = Client.order_by_name.map { |c| [c.name, c.id] }
        @products = Product.all.map { |p| [p.name, p.id] }
        @payment_methods = Rails.application.config_for(:constants)["payment_methods"]
        render :new, status: :unprocessable_entity
      end
  end

  def update
      if @purchase.update(purchase_params)
        redirect_to @purchase
        flash[:success] = "Purchase was successfully updated"
      else
        @clients = Client.order_by_name.map { |c| [c.name, c.id] }
        @products = Product.all.map { |p| [p.name, p.id] }
        @payment_methods = Rails.application.config_for(:constants)["payment_methods"]
        render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @purchase.destroy
      redirect_to purchases_url
      flash[:success] = "Purchase was successfully deleted"
  end

  def clear_filters
    clear_session(:filter_workout_group, :filter_status)
    redirect_to purchases_path
  end

  def filter
    # see application_helper
    clear_session(:filter_workout_group, :filter_status)
    # Without the ors (||) the sessions would get set to nil when redirecting to purchases other than through the
    # filter form (e.g. by clicking purchases on the navbar) (as the params items are nil in these cases)
    session[:filter_workout_group] = params[:workout_group] || session[:filter_workout_group]
    session[:filter_status] = params[:status] || session[:filter_status]
    redirect_to purchases_path
  end

  private

    def expire_purchases
      Purchase.not_expired.each do |p|
        p.update({expired: true}) if p.expired?
      end
    end

    def set_purchase
      @purchase = Purchase.find(params[:id])
    end

    def purchase_params
      params.require(:purchase).permit(:client_id, :product_id, :payment, :dop, :payment_mode, :invoice, :note, :adjust_restart, :ar_payment, :ar_date)
    end

    def initialize_sort
      session[:sort_option] = params[:sort_option] || session[:sort_option] || 'client_dop'
    end

    def handle_search
      #@purchases = Purchase.joins(product: [:workout_group]).where(workout_groups: { name: session[:filter_workout_group] }) if session[:filter_workout_group].present?
      @purchases = Purchase.with_workout_group(session[:filter_workout_group]) if session[:filter_workout_group].present?
      @purchases = @purchases.select { |p| session[:filter_status].include?(p.status) } if session[:filter_status].present?
      # hack to convert back to ActiveRecord for the order_by scopes of the index method, which will fail on an Array
      @purchases = Purchase.where(id: @purchases.map(&:id)) if @purchases.is_a?(Array)
    end
end
