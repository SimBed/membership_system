class ShopController < ApplicationController
  # before_action :superadmin_account

  def index
    @test_price = Price.where(name: 'razor_test').first
    @products = Product.package.includes(:workout_group).order_by_name_max_classes.reject(&:pt?)
  end
end
