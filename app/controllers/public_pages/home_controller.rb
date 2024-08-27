class PublicPages::HomeController < ApplicationController
  before_action :set_timetable, only: [:welcome, :group_classes, :space_home]
  before_action :daily_account_limit, only: [:create_account]
  before_action :set_admin_status
  layout 'public'

  def welcome
    # toggle for a navbar class so photograph is not hidden by an opaque black navbar
    @home = true
  end

  def group_classes
    @home = true
    @trial_price = Product.trial.first.base_price_at(Time.zone.now).price
    @products = Product.online_order_by_wg_classes_days.reject { |p| p.base_price_at(Time.zone.now).nil? }.reject(&:trial?)
    @group = true
    @default_class_number_type = 'unlimited'
  end

  def signup
    @account = Account.new
    @client = Client.new
    declaration = @client.build_declaration
    @gender_options = Rails.application.config_for(:constants)['genders']
    render layout: 'login'
  end

  def create_account
    @client = Client.new(client_params)
    if @client.save
      outcome = AccountCreator.new(account_params).create
      if outcome.success?
        log_in outcome.account
        @renewal = Renewal.new(@client)
        redirect_to client_shop_path @client
        flash_message(*Whatsapp.new(whatsapp_params('new_signup', outcome.password)).manage_messaging)
      else
        # if the signup didnt complete, want to try again, not keep just the client bit
        @client.destroy
        @client = Client.new(client_params)
        @account = outcome.account # the invalid account object with its error messages is returned by the Struct
        @gender_options = Rails.application.config_for(:constants)['genders'] 
        render 'signup', layout: 'login'
      end
    else
      @account = Account.new
      @gender_options = Rails.application.config_for(:constants)['genders']      
      render 'signup', layout: 'login', status: :unprocessable_entity
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
    @entries_hash = Timetable.display_entries    
  end

  def daily_account_limit
    daily_accounts_count = Account.where("DATE(created_at)='#{Time.zone.today.to_date}'").size
    return unless daily_accounts_count >= Setting.daily_account_limit

    if Setting.daily_account_limit_triggered == false
      Whatsapp.new(receiver: 'me', message_type: 'daily_account_limit',
                   variable_contents: { first_name: 'Dan' }).manage_messaging
    end
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
    params.require(:client).permit(:first_name, :last_name, :dob, :gender, :email, :whatsapp_country_code, :whatsapp_raw, :phone_raw, :instagram,
                                   declaration_attributes: [:heart_trouble, :chest_pain_activity, :chest_pain_no_activity, :dizziness, :drugs, :doctors_permit,
                                                        :pain, :fracture, :joint, :ligament, :tendon, :muscle, :skeletal, :osteoarthritis, :prolapse, :hernia, :postnatal,
                                                        :diabetes, :cardiovascular, :respiratory, :digestive, :blood, :autoimmune, :nutrient, :hormonal, :endocrine, :migraine, :allergies, :pcos, :menopause, :gynaecological, :epilepsy, :sight, :kidney, :cancer,
                                                        :eating, :depression, :anxiety, :ptsd, :neurodevelopmental, :psychiatric,
                                                        :fertility, :pregnant, :birth, :smoker, :alcohol, :drug,
                                                        :injury, :injury_note, :medication, :medication_note, :none, :contact_first_name, :contact_last_name, :contact_relationship, :contact_phone_raw,
                                                        :terms_and_conditions, :payment_policy, :privacy_policy, :indemnity
                                                       ]
                                    )
                                    .to_h.deep_merge(phone_country_code: 'IN', modifier_is_client: true, declaration_attributes: {contact_phone_country_code: 'IN'})
                                    # annoying that deep_merge doesnt work with params
                                    # no anwers here particulary satisfactory https://stackoverflow.com/questions/40981206/how-to-merge-nested-attributes-in-permit-rails                                 )
                            
  end

  def account_params
    params.require(:client).permit(:email).merge(account_holder: @client, role_name: 'client')
  end

  def whatsapp_params(message_type, password)
    { receiver: @client,
      message_type:,
      triggered_by: 'client',
      variable_contents: { password: } }
  end
end


