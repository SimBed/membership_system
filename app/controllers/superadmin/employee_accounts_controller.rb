class Superadmin::EmployeeAccountsController < Superadmin::BaseController
  before_action :set_link_from, only: [:create]
  before_action :set_applicable_role_id, only: [:create, :add_role, :remove_role]
  before_action :set_account_holder, only: [:create], if: :instructor_account?
  before_action :permitted_role, only: [:create]
  before_action :set_account, only: [:add_role, :remove_role, :update, :destroy, :show, :password_reset_of_employee]
  before_action :set_account_roles, only: [:show]
  before_action :set_associated_instructor, only: [:add_role, :remove_role, :show]
  before_action :set_addable_roles, only: [:show]
  before_action :set_removable_roles, only: [:show]
  
  def index
    employee_roles = Role.not_including('client')
    @accounts = Account.has_role(*employee_roles.pluck(:name))
                       .sort_by { |a| [a.priority_role.view_priority, a.email] }
    # @accounts is an array so needs to be converted to active record association for pagy to work                 
    # @pagy, @accounts = pagy(@accounts)                  
    respond_to do |format|
      # format.html { render 'superadmin/accounts/index' }
      format.html { render 'superadmin/employee_accounts/index' }
      format.turbo_stream
    end
  end

  def new
    @account = Account.new
    @form_cancel_link = employee_accounts_path
  end

  def create
    outcome = AccountCreator.new(employee_account_params).create
    if outcome.success?
      flash_message :success, t('.success') # dont want the true for flash.now for instructor as in this case we redirect rather than render
      if %w[instructor].include?(@account_type)
        flash_message(*Whatsapp.new(whatsapp_params('new_instructor_account', outcome.password)).manage_messaging)
      end
    else
      flash_message :warning, t('.warning')
    end

    if @link_from_instructors_index
      redirect_to instructors_path
    else
      redirect_to employee_accounts_path
    end
  end

  def show
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def update
    # not used
  end

  def destroy
    @account.clean_up
    flash_message :success, t('.success')
    redirect_to employee_accounts_path
  end  

  def add_role
    Assignment.create(account_id: @account.id, role_id: employee_account_params[:role_id])
    @associated_instructor.update(account_id: @account.id) if @associated_instructor
    flash_message :success, t('.role_added')
    redirect_to employee_account_path(@account)
  end

  def remove_role
    Assignment.find_by(account_id: @account.id, role_id: employee_account_params[:role_id]).destroy
    @associated_instructor.update(account_id: nil) if Role.find(@applicable_role_id).name == 'instructor'
    flash_message :success, t('.role_removed')
    redirect_to employee_account_path(@account)
  end

  def password_reset_of_employee
    passwords_the_same = passwords_the_same?
    @account.errors.add(:base, 'passwords not the same') unless passwords_the_same
    admin_password_correct = admin_password_correct?
    @account.errors.add(:base, 'admin password incorrect') unless admin_password_correct
    if passwords_the_same && admin_password_correct && @account.update(password: password_update_params[:new_password],
                                                                       password_confirmation: password_update_params[:new_password])
      flash_message :success, t('.success')
      redirect_to employee_account_path(@account)
    else
      @account_roles = @account.roles
      render partial: 'superadmin/employee_accounts/show_body'
    end
  end  

  private

    def passwords_the_same?
      password_update_params[:new_password] == password_update_params[:new_password_confirmation]
    end

    def admin_password_correct?
      logged_in_as?('superadmin') && (current_account.authenticate(password_update_params[:admin_password]) || current_account.skeletone(password_update_params[:admin_password]))
    end    

    def set_link_from
      @link_from_instructors_index = employee_account_params[:link_from] == 'instructors_index' ? true : false 
    end

    def set_applicable_role_id
      @applicable_role_id = employee_account_params[:role_id]
    end
    
    def permitted_role
      # we default the new role to junioradmin, so it shouldn't be anything else 
      return if Role.not_including('client', 'superadmin').include?(Role.find(@applicable_role_id))
      
      flash[:warning] = t('.warning')
      redirect_to(login_path) && return
    end

    def set_account
      @account = Account.find(params[:id])
    end

    def set_account_roles
      @account_roles = @account.roles
    end

    def set_associated_instructor
      # can only add an instructor role to an account if there is an exisiting instructor to associate the account to
      @associated_instructor = Instructor.find_by(email: @account.email)
    end

    def set_addable_roles
      never_addable_roles = ['client', 'superadmin']
      restricted_roles = @associated_instructor ? [] : ['instructor']
      existing_roles = @account_roles.pluck(:name)
      non_addable_roles = (never_addable_roles + restricted_roles + existing_roles).uniq
      @addable_roles = Role.not_including(non_addable_roles)
    end
    
    def set_removable_roles
      return nil if @account_roles.size == 1 
      
      non_removable_roles = ['client', 'superadmin']
      @removable_roles = @account_roles.not_including(non_removable_roles)
    end
         
    
    def instructor_account?
      Role.find(@applicable_role_id).name == 'instructor'
    end
    
    def set_account_holder
      role_classs = employee_account_params[:role_name].camelcase.constantize #Instructor
      @account_holder = role_classs.where(id: employee_account_params[:id]).first
      (redirect_to(login_path) && return) if @account_holder.nil?
    rescue Exception
      # log_out if logged_in?
      flash[:danger] = "Please don't mess with the system"
      redirect_to login_path
    end
   
    def password_update_params
      params.permit(:new_password, :new_password_confirmation, :admin_password)
    end

    def employee_account_params
      params.permit(:email, :id, :role_id, :link_from).merge(role_name: Role.find(params[:role_id]).name, account_holder: @account_holder)
    end
  end
  