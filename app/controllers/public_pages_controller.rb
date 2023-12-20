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

  def signup
    @account = Account.new
    @client = Client.new
    render layout: 'login'
  end

  def create_account
    @client = Client.new(client_params)
    if @client.save
      result = AccountCreator.new(account_params).create
      if result.success?
        log_in result.account
        @renewal = Renewal.new(@client)
        redirect_to client_shop_path @client
        flash_message(*Whatsapp.new(whatsapp_params('new_signup', result.password)).manage_messaging)
      else
        @account = result.account # the invalid account object with its error messages is returned by the Struct
        render 'signup', layout: 'login'
      end
    else
      @account = Account.new
      render 'signup', layout: 'login', status: 422
    end
  end

  def wedontsupport
    render layout: 'client'
  end

  def hearts
    render layout: false
  end

  def sell; end

  def welcome_home; end

  def space_home; end

  private

  def set_timetable
    @timetable = Timetable.find(Rails.application.config_for(:constants)['timetable_id'])
    @days = @timetable.table_days.order_by_day
    @entries_hash = {}
    @days.each do |day|
      @entries_hash[day.name] = Entry.where(table_day_id: day.id).includes(:table_time, :workout).order_by_start
    end
    # used to establish whether 2nd day in the timetable slider is tomorrow or not
    @todays_day = Time.zone.today.strftime('%A')
    @tomorrows_day = Date.tomorrow.strftime('%A')
  end

  def daily_account_limit
    daily_accounts_count = Account.where("DATE(created_at)='#{Time.zone.today.to_date}'").size
    return unless daily_accounts_count >= Setting.daily_account_limit

    Whatsapp.new(receiver: 'me', message_type: 'daily_account_limit',
                 variable_contents: { first_name: 'Dan' }).manage_messaging if Setting.daily_account_limit_triggered == false
    # mitigate multiple messages being sent once the message has been sent once
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
    params.require(:client).permit(:email).merge(account_holder: @client, ac_type: 'client')
  end

  def whatsapp_params(message_type, password)
    { receiver: @client,
      message_type:,
      triggered_by: 'client',
      variable_contents: { password: } }
  end
end
