class Shared::DeclarationsController < Shared::BaseController
  skip_before_action :admin_or_instructor_account
  before_action :set_client, except: :index
  before_action :correct_account, only: [:new, :update] 
  before_action :already_declared, only: [:new, :update] 
  before_action :correct_account_or_admin_or_instructor_account, only: :show
  before_action :set_declaration, only: [:show, :update] 
  before_action :admin_or_instructor_account, only: :index

  def index
    @declarations = Declaration.order_by_date
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

  def show; end

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

  def correct_account_or_admin_or_instructor_account
    return if logged_in_as?('admin', 'superadmin', 'instructor')

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

end