class ShopController < ApplicationController
  before_action :superadmin_account

  def index
    @products = Product.package.includes(:workout_group).order_by_name_max_classes.reject {|p| p.pt?}
  end
end
