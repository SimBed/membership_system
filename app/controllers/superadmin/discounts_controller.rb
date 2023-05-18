class Superadmin::DiscountsController < Superadmin::BaseController
  before_action :set_discount, only: %i[ show edit update destroy ]

  def index
    @discount_type_hash = { current: {
                              base: Discount.current(Time.zone.now.to_date).by_rationale('Base'),
                              commercial: Discount.current(Time.zone.now.to_date).by_rationale('Commercial'),
                              discretion: Discount.current(Time.zone.now.to_date).by_rationale('Discretion'),
                              oneoff: Discount.current(Time.zone.now.to_date).by_rationale('Oneoff'),
                              status: Discount.current(Time.zone.now.to_date).by_rationale('Status'),
                              renewal: Discount.current(Time.zone.now.to_date).by_rationale('Renewal')},
                            not_current: {
                              base: Discount.not_current(Time.zone.now.to_date).by_rationale('Base'),
                              commercial: Discount.not_current(Time.zone.now.to_date).by_rationale('Commercial'),
                              discretion: Discount.not_current(Time.zone.now.to_date).by_rationale('Discretion'),
                              oneoff: Discount.not_current(Time.zone.now.to_date).by_rationale('Oneoff'),
                              status: Discount.not_current(Time.zone.now.to_date).by_rationale('Status'),
                              renewal: Discount.not_current(Time.zone.now.to_date).by_rationale('Renewal')}
                          }
  end

  def new
    @discount = Discount.new
    prepare_items_for_dropdowns
  end

  def edit
    prepare_items_for_dropdowns
  end

  def create
    @discount = Discount.new(discount_params)
    if @discount.save
      redirect_to superadmin_discounts_path
      flash[:success] = t('.success')
    else
      prepare_items_for_dropdowns
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @discount.update(discount_params)
      redirect_to superadmin_discounts_path
      flash[:success] = t('.success')
    else
      prepare_items_for_dropdowns
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @discount.destroy
    redirect_to superadmin_discounts_path
    flash[:success] = t('.success')
  end

  private
    def prepare_items_for_dropdowns
      @discount_names = DiscountReason.order_by_name
      @discount_reasons = Rails.application.config_for(:constants)['discount_rationales']
    end

    def set_discount
      @discount = Discount.find(params[:id])
    end

    def discount_params
      # the update method (and therefore the discount_params method) is used through a form but also clicking on a link on the discounts page
      return {end_date: Time.zone.now.to_date.yesterday } if params[:current].present? && params[:current] == 'false'
      return {end_date: 100.years.from_now } if params[:current].present? && params[:current] == 'true'

      params.require(:discount).permit(:discount_reason_id, :percent, :fixed, :pt, :group, :online, :aggregatable, :start_date, :end_date)
    end
end
