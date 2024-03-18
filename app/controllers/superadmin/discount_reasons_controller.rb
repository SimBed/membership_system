class Superadmin::DiscountReasonsController < Superadmin::BaseController
  before_action :set_discount_reason, only: [:show, :edit, :update, :destroy]

  def index
    @discount_reasons_current = DiscountReason.current.order_by_rationale
    @discount_reasons_not_current = DiscountReason.not_current.order_by_rationale
    @unused_ids = DiscountReason.unused.map(&:id)
  end

  def new
    @discount_reason = DiscountReason.new
    prepare_items_for_dropdowns
  end

  def edit
    prepare_items_for_dropdowns
  end

  def create
    @discount_reason = DiscountReason.new(discount_reason_params)
    if @discount_reason.save
      redirect_to discount_reasons_path
      flash[:success] = t('.success')
    else
      prepare_items_for_dropdowns
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @discount_reason.update(discount_reason_params)
      redirect_to discount_reasons_path
      flash[:success] = t('.success')
    else
      prepare_items_for_dropdowns
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @discount_reason.destroy
    redirect_to discount_reasons_path
    flash[:success] = t('.success')
  end

  private

  def prepare_items_for_dropdowns
    # @discount_reason_names = Rails.application.config_for(:constants)['discount_names']
    @discount_reason_names = Setting.discount_reason_names
    @discount_reason_rationales = Rails.application.config_for(:constants)['discount_rationales']
    @discount_reason_applications = Rails.application.config_for(:constants)['discount_applications']
  end

  def set_discount_reason
    @discount_reason = DiscountReason.find(params[:id])
  end

  def discount_reason_params
    [:student, :friends_and_family, :first_package, :renewal_pre_package_expiry, :renewal_post_package_expiry, :renewal_pre_trial_expiry,
     :renewal_post_trial_expiry].each do |column|
      params['discount_reason'][column] = false
    end
    (applies_to_param = { params['discount_reason']['applies_to'] => true }) if DiscountReason.column_names.any? params['discount_reason']['applies_to']
    params.require(:discount_reason)
          .permit(:name, :rationale, :student, :friends_and_family, :first_package, :renewal_pre_package_expiry,
                  :renewal_post_package_expiry, :renewal_pre_trial_expiry, :renewal_post_trial_expiry, :current)
          .merge applies_to_param
  end
end
