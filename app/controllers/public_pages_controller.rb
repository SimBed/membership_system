class PublicPagesController < ApplicationController
  layout 'public'
  
  def welcome
    @timetable = Timetable.find(Setting.timetable) 
    @days = @timetable.table_days.order_by_day    
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
    @timetable = Timetable.find(Setting.timetable) 
    @days = @timetable.table_days.order_by_day
    # @morning_times = @timetable.table_times.during('morning').order_by_time
    # @afternoon_times = @timetable.table_times.during('afternoon').order_by_time
    # @evening_times = @timetable.table_times.during('evening').order_by_time
  end

  def signup
    @account = Account.new
    render layout: 'login'
  end 

  def create_account
    'check maximum daily accounts not exceeded'
    @client = Client.new(client_params)
    if @client.save
      @password = Account.password_wizard(6)
      @account = Account.new(account_params)
      if @account.save
        associate_account_holder_to_account
        flash_message :success, t('.success')
        # flash_message(*Whatsapp.new(whatsapp_params('new_account')).manage_messaging)
        redirect_to login_path
        flash[:success] = 'Account created. Please login to make a purchase.'
        # flash_message :success, t('.success', name: @client.name)
      else
        flash.now[:danger] = 'Unable to create account for client, please contact The Space'
      end
    else
      flash.now[:danger] = 'Unable to create account, please contact The Space'
      # render 'signup'
    end

  end
  
  private

  def associate_account_holder_to_account
    @client.update(account_id: @account.id)
  end
  
  def client_params
    params.require(:account).permit(:first_name, :last_name, :email, :phone, :whatsapp, :instagram)
  end
  
  def account_params
    password_params = { password: @password, password_confirmation: @password }
    activation_params = { activated: true, ac_type: 'client' }
    params.require(:account).permit(:email).merge(activation_params).merge(password_params)
  end

end
