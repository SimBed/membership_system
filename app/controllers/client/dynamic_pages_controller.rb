class Client::DynamicPagesController < Client::BaseController
  
  def book
    session[:booking_day] = params[:booking_day] || session[:booking_day] || '0'
    @wkclasses_show = Wkclass.limited.show_in_bookings_for(@client).order_by_reverse_date
    @open_gym_wkclasses = Wkclass.unlimited.show_in_bookings_for(@client).order_by_reverse_date
    @my_bookings = Wkclass.booked_for(@client).show_in_bookings_for(@client).order_by_reverse_date
    # switching the order round (as below) returns wkclasses with booked attendances not of @client. Couldn't figure this out
    # Wkclass.show_in_bookings_for(@client).booked_for(@client).order_by_reverse_date
    # Wkclass.show_in_bookings_for(c).merge(Wkclass.booked_for(c)).order_by_reverse_date
    @days = (Time.zone.today..Time.zone.today.advance(days: Setting.visibility_window_days_ahead)).to_a
    # Should be done in model
    @wkclasses_show_by_day = []
    @opengym_wkclasses_show_by_day = []
    @days.each do |day|
      @wkclasses_show_by_day.push(@wkclasses_show.on_date(day))
      @opengym_wkclasses_show_by_day.push(@open_gym_wkclasses.on_date(day))
    end
    @other_services = OtherService.all
    # include attendances and wkclass so can find last booked session in PT package without additional query
    @purchases = @client.purchases.not_fully_expired.service_type('group').package.order_by_dop.includes(:freezes, :adjustments, :penalties, attendances: [:wkclass])
    @renewal = Renewal.new(@client)
    params[:booking_section] = nil if params[:major_change] == 'true' # do full page reload if major change
    # redirect_to client_book_path(@client)
    # request.format = :html
    # respond_to do |format|
    #   format.html
    # end
    respond_to do |format|
      format.html
      case params[:booking_section]
      when 'group'
        format.turbo_stream
      when 'opengym'
        format.turbo_stream { render :book_opengym }
      when 'my_bookings'
        format.turbo_stream { render :book_my_bookings }
      else
        format.turbo_stream { render :book_all_streams }
      end
    end
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
    @default_product_type = @renewal.default_product_type
  end  
end
