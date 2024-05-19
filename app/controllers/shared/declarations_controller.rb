class Shared::DeclarationsController < Shared::BaseController
  skip_before_action :admin_or_instructor_account
  before_action :set_client, only: [:new, :update, :show] 
  before_action :correct_account, only: [:new, :update] 
  before_action :already_declared, only: [:new, :update] 
  before_action :correct_account_or_junioradmin_or_instructor_account, only: :show
  before_action :set_declaration, only: [:show, :update] 
  before_action :junioradmin_or_instructor_account, only: :index
  before_action :initialize_sort, only: :index
  before_action :set_admin_status, only: :index

  def index
    @declarations = Declaration.includes(:client)
    handle_filter
    handle_search
    handle_sort
    handle_pagination
    # handle_index_response    
  end

  def new
    @declaration = @client.build_declaration
    @gender_options = Rails.application.config_for(:constants)['genders']
  end

  # the declaration is created from a form scoped to an exisiting client, so the form defaults to a patch (update request) (with nested attributes for the new declaration)
  # so consider a declaration creation as an update (of a client)
  def update
    if @client.update(client_params)
      flash_message :success, t('.success')
      redirect_to client_book_path(@client)
    else
      @gender_options = Rails.application.config_for(:constants)['genders']
      render :new, status: :unprocessable_entity
    end
  end  

  def show
    @declaration_updates = @declaration.declaration_updates.order_by_submitted
    @client_view = true if logged_in_as?('client')
    @cancel_button = true unless @client_view
  end

  def clear_filters
    clear_session(:filter_initial_health_issue, :search_declaration_client_name)
    redirect_to declarations_path
  end  

  def filter
    clear_session(:filter_initial_health_issue)
    session[:search_declaration_client_name] = params[:search_declaration_client_name] || session[:search_declaration_client_name]
    # set_session(:has_health_issue)
    session["filter_initial_health_issue"] = params[:initial_health_issue] || session["filter_initial_health_issue"]
    redirect_to declarations_path
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end

  def set_declaration
    @declaration = @client.declaration
  end

  def correct_account
    return if current_account?(@client&.account)

    flash_message :warning, t('.warning')
    redirect_to login_path
  end

  def correct_account_or_junioradmin_or_instructor_account
    return if logged_in_as?('junioradmin', 'admin', 'superadmin', 'instructor')

    return if current_account?(@client&.account)

    flash_message :warning, t('.warning')
    redirect_to login_path
  end  

  def already_declared
    return unless @client.declaration

    flash_message :warning, t('.warning')
    redirect_to login_path
  end  

  def client_params
    params.require(:client).permit(:dob, :gender,
                                   declaration_attributes: [:heart_trouble, :chest_pain_activity, :chest_pain_no_activity, :dizziness, :drugs, :doctors_permit,
                                                        :pain, :fracture, :joint, :ligament, :tendon, :muscle, :skeletal, :osteoarthritis, :prolapse, :hernia, :postnatal,
                                                        :diabetes, :cardiovascular, :respiratory, :digestive, :blood, :autoimmune, :nutrient, :hormonal, :endocrine, :migraine, :allergies, :pcos, :menopause, :gynaecological, :epilepsy, :sight, :kidney, :cancer,
                                                        :eating, :depression, :anxiety, :ptsd, :neurodevelopmental, :psychiatric,
                                                        :fertility, :pregnant, :birth, :smoker, :alcohol, :drug,
                                                        :injury, :injury_note, :medication, :medication_note, :none, :contact_first_name, :contact_last_name, :contact_relationship, :contact_phone_raw,
                                                        :terms_and_conditions, :payment_policy, :privacy_policy, :indemnity
                                                       ]
                                    )
                                    .to_h.deep_merge(declaration_attributes: {contact_phone_country_code: 'IN'})
                                    # annoying that deep_merge doesnt work with params
                                    # no anwers here particulary satisfactory https://stackoverflow.com/questions/40981206/how-to-merge-nested-attributes-in-permit-rails                                 )
                            
  end

  def initialize_sort
    session[:declaration_sort_option] = params[:declaration_sort_option] || session[:declaration_sort_option] || 'submitted'
  end

  def handle_search
    handle_name_search
  end

  def handle_name_search
    return if session[:search_declaration_client_name].blank?

    @declarations = @declarations.name_like(session[:search_declaration_client_name])
  end

  def handle_filter
    %w[initial_health_issue].each do |key|
      @declarations = @declarations.send(key) if session["filter_#{key}"].present?
    end
  end

  def handle_sort
    @declarations = @declarations.send("order_by_#{session[:declaration_sort_option]}")
  end

  def handle_pagination
      @pagy, @declarations = pagy(@declarations, items: 100)
  end  

end