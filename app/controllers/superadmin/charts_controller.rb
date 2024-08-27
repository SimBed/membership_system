class Superadmin::ChartsController < Superadmin::BaseController
  before_action :set_utc_timezone
  after_action :set_local_timezone

  def purchase_count_by_week
    render json: Purchase.where(id: Purchase.pluck(:id)).group_by_week(:dop).count   
  end

  private

  def set_utc_timezone
    Purchase.default_timezone = :utc
  end

  def set_local_timezone
    Purchase.default_timezone = :local
  end

end