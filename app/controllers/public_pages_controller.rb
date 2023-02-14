class PublicPagesController < ApplicationController
  before_action :set_timetable, only: [:welcome, :space_home]
  before_action :account_limit, only: [:create_account]  
  layout 'public'
  
  def welcome
    if logged_in_as?('junioradmin', 'admin', 'superadmin')
      # not && return won't work because of precedence of operator over method call
      redirect_to admin_clients_path and return
    elsif logged_in_as?('client')
      redirect_to client_client_path(current_account.clients.first) and return
    elsif logged_in_as?('partner')
      redirect_to admin_partner_path(current_account.partners.first) and return
    end
    # render template: 'auth/sessions/new'
  end

  def welcome_home
  end
  
  def space_home
    # @morning_times = @timetable.table_times.during('morning').order_by_time
    # @afternoon_times = @timetable.table_times.during('afternoon').order_by_time
    # @evening_times = @timetable.table_times.during('evening').order_by_time
  end

  def signup
    @account = Account.new
    @client = Account.new
    render layout: 'login'
  end 

  def create_account
    @client = Client.new(client_params)
    if @client.save
      @password = Account.password_wizard(6)
      @account = Account.new(account_params)
      if @account.save
        associate_account_holder_to_account
        # flash_message :success, t('.success')
        # flash_message(*Whatsapp.new(whatsapp_params('new_account')).manage_messaging)
        # redirect_to login_path
        # flash[:success] = "Welcome to The Space #{@client.first_name}. Your account has been created. Please login to make a purchase."
        log_in @account
        redirect_to client_shop_path @client
        flash_message(*Whatsapp.new(whatsapp_params('new_signup')).manage_messaging)
        # flash[:success] = "Welcome to The Space #{@client.first_name}. Your account has been created. You will receive a whatsapp with your password to login in future. Please contact The Space if you need any help to complete your purchase."        
        # flash_message :success, t('.success', name: @client.name)
      else
        flash.now[:danger] = 'Unable to create account for client, please contact The Space'
        render 'signup', layout: 'login'
      end
    else
      flash.now[:danger] = 'Unable to create account, please contact The Space'
      @account = Account.new
      render 'signup', layout: 'login'
    end

  end

  def shop
    # @products = Product.package.includes(:workout_group).order_by_name_max_classes.reject {|p| p.pt? || p.base_price.nil?}
    @products = Product.online_order_by_wg_classes_days.reject {|p| p.base_price.nil?}
    # https://blog.kiprosh.com/preloading-associations-while-using-find_by_sql/
    # https://apidock.com/rails/ActiveRecord/Associations/Preloader/preload
    ActiveRecord::Associations::Preloader.new.preload(@products, :workout_group)
    render layout: 'white_canvas'
  end

  def thankyou
    render layout: 'white_canvas'
  end

  def sell
  end
  
  private

  def set_timetable
    # if Rails.env.test?
    #   @timetable = Timetable.first
    # else
    #   @timetable = Timetable.find(Setting.timetable)
    # end
    @timetable = Timetable.find(Setting.timetable)
    @days = @timetable.table_days.order_by_day    
  end

  def account_limit
    daily_accounts_count = Account.where("DATE(created_at)='#{Date.today.to_date}'").size
    # Setting/I18n
    if daily_accounts_count > 10
      # flash_message(*Whatsapp.new(whatsapp_params('new_account')).manage_messaging)
      Whatsapp.new(receiver:'me', message_type:'new_purchase', variable_contents: { first_name: 'Dan', me?: true }).manage_messaging
      redirect_to signup_path
      flash[:warning] = 'Sorry, the site limit has been exceeded. This is a temporary issue. Please contact The Space or try again tomorrow. The site developer has been notified.'
    end
  end

  def associate_account_holder_to_account
    @client.update(account_id: @account.id)
  end
  
  def client_params
    params.require(:client).permit(:first_name, :last_name, :email, :phone, :whatsapp, :whatsapp_country_code, :instagram).merge(modifier_is_admin: false)
  end
  
  def account_params
    password_params = { password: @password, password_confirmation: @password }
    activation_params = { activated: true, ac_type: 'client' }
    params.require(:client).permit(:email).merge(activation_params).merge(password_params)
  end

  def whatsapp_params(message_type)
    { receiver: @client,
      message_type: message_type,
      admin_triggered: false,
      variable_contents: { password: @password } }      
  end

end
