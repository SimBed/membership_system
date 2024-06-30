class Client::DynamicPagesController < Client::BaseController

  def book
    # temporary so clients who go to the old url dont get an error
    redirect_to client_bookings_path(@client)
  end

  def shop
    @products = Product.online_order_by_wg_classes_days.reject { |p| p.base_price_at(Time.zone.now).nil? }.reject(&:trial?)
    # @products = @products.reject {|p| p.trial?} if logged_in? && current_account.client.has_purchased?
    # https://blog.kiprosh.com/preloading-associations-while-using-find_by_sql/
    # https://apidock.com/rails/ActiveRecord/Associations/Preloader/preload
    # ActiveRecord::Associations::Preloader.new.preload(@products, :workout_group)
    # Rails 7 update
    # https://stackoverflow.com/questions/74430650/rails-7-activerecordassociationspreloader-new-preload
    ActiveRecord::Associations::Preloader.new(
      records: @products,
      associations: :workout_group
    ).call
    @renewal = Renewal.new(@client)
    @trial_price = Product.trial.space_group.first.base_price_at(Time.zone.now).price
    @default_class_number_type = @renewal.default_class_number_type
  end  
end
