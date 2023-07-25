class PublicPagesController < ApplicationController
  before_action :set_timetable, only: [:welcome, :group_classes, :space_home]
  before_action :daily_account_limit, only: [:create_account]
  layout 'public'

  def welcome
    # toggle for a navbar class so photograph is not hidden by an opaque black navbar
    @home = true
  end

  def group_classes
    @home = true
    @trial_price = Product.trial.first.base_price_at(Time.zone.now).price
    @products = Product.online_order_by_wg_classes_days.reject { |p| p.base_price_at(Time.zone.now).nil? }.reject(&:trial?)    
    @menu = PackageMenu.new()
    @group = true
  end

  def welcome_home; end

  def space_home; end

  def signup
    @account = Account.new
    @client = Client.new
    render layout: 'login'
  end

  def create_account
    @client = Client.new(client_params)
    if @client.save
      @password = Account.password_wizard(Setting.password_length)
      @account = Account.new(account_params)
      if @account.save
        Assignment.create(account_id: @account.id, role_id: Role.find_by(name: 'client').id)
        associate_account_holder_to_account
        log_in @account
        @renewal = Renewal.new(@client)
        redirect_to client_shop_path @client
        flash_message(*Whatsapp.new(whatsapp_params('new_signup')).manage_messaging)
      else
        render 'signup', layout: 'login'
      end
    else
      @account = Account.new
      render 'signup', layout: 'login'
    end
  end

  def shop
    # @products = Product.package.includes(:workout_group).order_by_name_max_classes.reject {|p| p.pt? || p.base_price.nil?}
    @products = Product.online_order_by_wg_classes_days.reject { |p| p.base_price_at(Time.zone.now).nil? }
    # https://blog.kiprosh.com/preloading-associations-while-using-find_by_sql/
    # https://apidock.com/rails/ActiveRecord/Associations/Preloader/preload
    ActiveRecord::Associations::Preloader.new.preload(@products, :workout_group)
    @renewal = { offer_online_discount?: true, renewal_offer: 'renewal_pre_expiry' }
    render 'wedontsupport', layout: 'white_canvas'
  end

  def thankyou
    render layout: 'white_canvas'
  end

  def sell; end

  def hearts
    render layout: false  
  end

  private

  def set_timetable
    @timetable = Timetable.find(Rails.application.config_for(:constants)['timetable_id'])
    @days = @timetable.table_days.order_by_day
    @entries_hash = {}
    @days.each do |day|
      @entries_hash[day] = Entry.where(table_day_id: day.id).includes(:table_time, :workout).order_by_start
    end
  end

  def daily_account_limit
    daily_accounts_count = Account.where("DATE(created_at)='#{Time.zone.today.to_date}'").size
    return unless daily_accounts_count >= Setting.daily_account_limit
    
    Whatsapp.new(receiver: 'me', message_type: 'daily_account_limit', variable_contents: { first_name: 'Dan', me?: true }).manage_messaging if Setting.daily_account_limit_triggered == false
    Setting.daily_account_limit_triggered = true
    flash[:warning] = t('.daily_account_limit')
    redirect_to signup_path
  end

  def associate_account_holder_to_account
    @client.modifier_is_client = true # should be irrelevant as the enhanced validations this causes have already happened and won't have been disturbed
    @client.update(account_id: @account.id)
  end

  def client_params
    params.require(:client).permit(:first_name, :last_name, :email, :phone_raw, :whatsapp_raw, :whatsapp_country_code, :instagram, :terms_of_service)
          .merge(phone_country_code: 'IN')
          .merge(modifier_is_client: true)
  end

  def account_params
    password_params = { password: @password, password_confirmation: @password }
    activation_params = { activated: true, ac_type: 'client' }
    params.require(:client).permit(:email).merge(activation_params).merge(password_params)
  end

  def whatsapp_params(message_type)
    { receiver: @client,
      message_type:,
      admin_triggered: false,
      variable_contents: { password: @password } }
  end
end
