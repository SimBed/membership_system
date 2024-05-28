require 'test_helper'

class SignupTest < ActionDispatch::IntegrationTest
  include SessionsHelper

  def setup
    @existing_client_account = accounts(:client_for_unlimited)
    @exiting_client_with_account = @existing_client_account.client
    @existing_client_without_account = clients(:bhavik)
    # changing all the Account fixtures just created to have been created a day earlier, so daily account limit not triggered
    # https://docs.rubocop.org/rubocop/configuration.html#:~:text=Disabling%20Cops%20within%20Source%20Code,-One%20or%20more&text=In%20cases%20where%20you%20want,an%20alias%20of%20rubocop%3Adisable%20.&text=One%20or%20more%20cops%20can,end%2Dof%2Dline%20comment.
    # rubocop:disable Rails/SkipsModelValidations
    Account.all.update_all(created_at: Time.zone.now.advance(days: -1))
    # rubocop:enable Rails/SkipsModelValidations
  end

  test 'blank signup form' do
    get signup_path

    assert_template 'public_pages/home/signup'
    post '/signup', params:
      { client:
       { first_name: '',
         last_name: '',
         dob: "1982-04-12",
         gender: 'male',
         email: '',
         whatsapp_country_code: 'IN',
         whatsapp_raw: '',
         phone_raw: '',
         instagram: '',
         declaration_attributes: {
          heart_trouble: true,
          indemnity: nil
         }
        }
      }

    assert_template 'public_pages/home/signup'
    assert_select 'h2', text: '9 errors prohibited this account from being created:'
    assert_select 'li', text: "First name can't be blank"
    assert_select 'li', text: "Last name can't be blank"
    assert_select 'li', text: "Email can't be blank"
    assert_select 'li', text: "Whatsapp can't be blank"
    assert_select 'li', text: "Declaration Doctor's clearance needed"
    assert_select 'li', text: "Declaration terms and conditions can't be blank"
    assert_select 'li', text: "Declaration payment policy can't be blank"
    assert_select 'li', text: "Declaration privacy policy can't be blank"
    assert_select 'li', text: "Declaration indemnity can't be blank"
  end

  test 'invalid whatsapp' do
    get signup_path

    assert_template 'public_pages/home/signup'
    post '/signup', params:
      { client:
       { first_name: 'Dani',
         last_name: 'Boi',
         dob: "1982-04-12",
         gender: 'male',         
         email: 'daniboi@gmail.com',
         whatsapp_country_code: 'IN',
         whatsapp_raw: '123456789',
         phone_raw: '',
         instagram: '',
         declaration_attributes: {
          heart_trouble: true,
          indemnity: nil
         } } }

    assert_template 'public_pages/home/signup'
    assert_select 'h2', text: '6 errors prohibited this account from being created:'
    assert_select 'li', text: 'Whatsapp is invalid'
    assert_select 'form input[type=text][value="Dani"]'
    assert_select 'form input[type=date][value="1982-04-12"]'
    assert_select 'form input[type=text][value="daniboi@gmail.com"]'
    assert_select 'form input[type=text][value^="daniboi"]'
    assert_select 'option[selected=selected]', 'IN +91'
    assert_select 'form input[type=text][value="123456789"]'
    assert_select 'input[name="client[declaration_attributes][heart_trouble]"][value="1"]'
  end

  test 'invalid GB whatsapp' do
    get signup_path

    assert_template 'public_pages/home/signup'
    post '/signup', params:
      { client:
       { first_name: 'Dani',
         last_name: 'Boi',
         dob: "1982-04-12",
         gender: 'male',         
         email: 'daniboi@gmail.com',
         whatsapp_country_code: 'GB',
         whatsapp_raw: '123456789',
         phone_raw: '',
         instagram: '',
         declaration_attributes: {
          heart_trouble: true,
          indemnity: nil
         } } }    
    # File.write('test_output.html',response.body)
    assert_template 'public_pages/home/signup'
    assert_select 'h2', text: '6 errors prohibited this account from being created:'
    assert_select 'li', text: 'Whatsapp is invalid'
    assert_select 'form input[type=text][value="Dani"]'
    assert_select 'form input[type=date][value="1982-04-12"]'
    assert_select 'form input[type=text][value="daniboi@gmail.com"]'
    assert_select 'form input[type=text][value^="daniboi"]'
    assert_select 'option[selected=selected]', 'GB +44'
    assert_select 'form input[type=text][value="123456789"]'
    assert_select 'input[name="client[declaration_attributes][heart_trouble]"][value="1"]'
  end

  # reconsider client model validations, as we dont want to lose new signups because of name duplication
  test 'invalid duplicate name' do
    assert_difference -> { Account.count } => 0, -> { Client.count } => 0, -> { Assignment.count } => 0 do
      post '/signup', params:
        { client:
         { first_name: @existing_client_without_account.first_name,
           last_name: @existing_client_without_account.last_name,
           dob: "1980-01-01",
           gender: 'female',           
           email: 'unique@gmail.com',
           whatsapp_country_code: 'GB',
           whatsapp_raw: '1234567891',
           declaration_attributes: {
            terms_and_conditions: true,
            payment_policy: true,
            privacy_policy: true,
            indemnity: true
           } } }  
    end
  end

  test 'invalid duplicate email' do
    assert_difference -> { Account.count } => 0, -> { Client.count } => 0, -> { Assignment.count } => 0 do
      post '/signup', params:
        { client:
         { first_name: 'uniquefirstname',
           last_name: 'uniquelastname',
           dob: "1980-01-01",
           gender: 'female',           
           email: @existing_client_account.email,
           whatsapp_country_code: 'GB',
           whatsapp_raw: '1234567891',
           declaration_attributes: {
            terms_and_conditions: true,
            payment_policy: true,
            privacy_policy: true,
            indemnity: true
           } } }
    end
  end

  test 'invalid duplicate whatsapp' do
    assert_difference -> { Account.count } => 0, -> { Client.count } => 0, -> { Assignment.count } => 0 do
      post '/signup', params:
        { client:
         { first_name: 'uniquefirstname',
           last_name: 'uniquelastname',
           dob: "1980-01-01",
           gender: 'female',           
           email: 'unique@gmail.com',
           whatsapp_country_code: 'IN',
           whatsapp_raw: @existing_client_without_account.whatsapp.slice(3, 10),
           declaration_attributes: {
            terms_and_conditions: true,
            payment_policy: true,
            privacy_policy: true,
            indemnity: true
           } } }
    end
  end

  # NOTE: whatsapp cant be blank on signup (but phone can)
  test 'invalid duplicate phone' do
    assert_difference -> { Account.count } => 0, -> { Client.count } => 0, -> { Assignment.count } => 0, -> { Declaration.count } => 0 do
      post '/signup', params:
        { client:
         { first_name: 'uniquefirstname',
           last_name: 'uniquelastname',
           dob: "1980-01-01",
           gender: 'female',           
           email: 'unique@gmail.com',
           whatsapp_country_code: 'IN',
           whatsapp_raw: "#{@existing_client_without_account.phone.slice(4, 10)}5",
           phone_raw: @existing_client_without_account.phone.slice(3, 10),
           declaration_attributes: {
            terms_and_conditions: true,
            payment_policy: true,
            privacy_policy: true,
            indemnity: true
           } } }
    end
  end

  test 'valid signup (Indian whatsapp), no health issues' do
    get signup_path

    assert_template 'public_pages/home/signup'
    # https://apidock.com/rails/v5.2.3/ActiveSupport/Testing/Assertions/assert_difference
    assert_difference -> { Account.count } => 1, -> { Client.count } => 1, -> { Assignment.count } => 1, -> { Declaration.count } => 1 do
      post '/signup', params:
        { client:
         { first_name: 'uniquefirstname',
           last_name: 'uniquelastname',
           dob: "1980-01-01",
           gender: 'female',           
           email: 'unique@gmail.com',
           whatsapp_country_code: 'IN',
           whatsapp_raw: '1234567891',
           phone_raw: '9123456789',
           instagram: '#myinsta',
           declaration_attributes: {
            terms_and_conditions: true,
            payment_policy: true,
            privacy_policy: true,
            indemnity: true
           } } }
    end
    client = Client.last

    assert_equal '+911234567891', client.whatsapp
    assert_equal '+919123456789', client.phone
    assert_redirected_to client_shop_path(assigns(:client).id)
    follow_redirect!
    # same tests as for 'test shop items correct for new client' from client_renewal_test
    assert_template 'client/dynamic_pages/shop'
    assert_empty response.body.scan(/Buy your first Package/)
    assert_empty response.body.scan(/Renew your Package/)
    assert_select 'div', text: 'unlimited 1 week trial'
    assert_select 'div', text: 'Try our classes. Meet our people'
    assert_select 'div', text: 'Our best value memberships for training regularly. The more you train, the better the value!'
    assert_select 'div', { count: 0, text: 'trial' }
    refute_empty response.body.scan(/data-amount="150000"/)
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 8,550'
    # temporarily remove until Razorpay glitch resolved
    # refute_empty response.body.scan(/data-amount="855000"/)
    assert_select 'li', text: 'Save Rs. 950'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 22,950'
    # temporarily remove until Razorpay glitch resolved    
    # refute_empty response.body.scan('data-amount="2295000"')
    assert_select 'li', text: 'Save Rs. 2,550'

    log_out
    new_account = Account.last
    # the new account has been given a random password, so lets rest it so we can login easily
    new_account.update(password: 'password', password_confirmation: 'password')
    log_in_as(new_account)

    assert_equal current_account, Account.last
    assert_equal 'client', current_role
  end

  test 'valid signup (GB whatsapp)' do
    get signup_path

    assert_template 'public_pages/home/signup'
    # https://apidock.com/rails/v5.2.3/ActiveSupport/Testing/Assertions/assert_difference
    assert_difference -> { Account.count } => 1, -> { Client.count } => 1, -> { Assignment.count } => 1, -> { Declaration.count } => 1 do
      post '/signup', params:
        { client:
         { first_name: 'uniquefirstname',
           last_name: 'uniquelastname',
           dob: "1980-01-01",
           gender: 'female',           
           email: 'unique@gmail.com',
           whatsapp_country_code: 'GB',
           whatsapp_raw: '1234567891',
           phone_raw: '9123456789',
           instagram: '#myinsta',
           declaration_attributes: {
            terms_and_conditions: true,
            payment_policy: true,
            privacy_policy: true,
            indemnity: true
           } } }
    end
    client = Client.last

    assert_equal '+441234567891', client.whatsapp
    assert_equal '+919123456789', client.phone
    assert_redirected_to client_shop_path(assigns(:client).id)
    follow_redirect!

    assert_template 'client/dynamic_pages/shop'
    log_out
    new_account = Account.last
    # the new account has been given a random password, so lets rest it so we can login easily
    new_account.update(password: 'password', password_confirmation: 'password')
    log_in_as(new_account)

    assert_equal current_account, Account.last
    assert_equal('client', current_role)
  end

  test 'public should not be able to create more than daily limit accounts on any one day' do
    Setting.daily_account_limit.times do |n|
      name = Faker::Name.unique.name
      joe_public = { first_name: name.split[0],
                     last_name: name.split[1],
                     email: "#{name.split.join}@gmail.com",
                     whatsapp_country_code: 'IN',
                     whatsapp_raw: "123456789#{n}",
                     declaration_attributes: {
                      terms_and_conditions: true,
                      payment_policy: true,
                      privacy_policy: true,
                      indemnity: true
                     } }
      assert_difference -> { Account.count } => 1, -> { Client.count } => 1, -> { Assignment.count } => 1, -> { Declaration.count } => 1 do
        post '/signup', params: { client: joe_public }
      end
    end

    name = Faker::Name.unique.name
    joe_public = { first_name: name.split[0],
                   last_name: name.split[1],
                   email: "#{name.split.join}@gmail.com",
                   whatsapp_country_code: 'IN',
                   whatsapp_raw: '1234567880',
                   declaration_attributes: {
                    terms_and_conditions: true,
                    payment_policy: true,
                    privacy_policy: true,
                    indemnity: true
                   } }
    assert_difference -> { Account.count } => 0, -> { Client.count } => 0, -> { Assignment.count } => 0, -> { Declaration.count } => 0 do
      post '/signup', params: { client: joe_public }
    end
  end

  test 'full range of health issues' do
    get signup_path

    assert_template 'public_pages/home/signup'
    # https://apidock.com/rails/v5.2.3/ActiveSupport/Testing/Assertions/assert_difference
    assert_difference -> { Account.count } => 1, -> { Client.count } => 1, -> { Assignment.count } => 1, -> { Declaration.count } => 1 do
      post '/signup', params:
        { client:
         { first_name: 'uniquefirstname',
           last_name: 'uniquelastname',
           dob: "1985-02-17",
           gender: 'female',           
           email: 'unique@gmail.com',
           whatsapp_country_code: 'IN',
           whatsapp_raw: '1234567891',
           phone_raw: '9123456789',
           instagram: '#myinsta',
           declaration_attributes: {
            heart_trouble: true, chest_pain_activity: true, chest_pain_no_activity: true, dizziness: true, drugs: true, doctors_permit: true,
            pain: true, fracture: true, joint: true, ligament: true, tendon: true, muscle: true, skeletal: true, osteoarthritis: true, prolapse: true, hernia: true, postnatal: true,
            diabetes: true, cardiovascular: true, respiratory: true, digestive: true, blood: true, autoimmune: true, nutrient: true, hormonal: true, endocrine: true, migraine: true,
            allergies: true, pcos: true, menopause: true, gynaecological: true, epilepsy: true, sight: true, kidney: true, cancer: true,
            eating: true, depression: true, anxiety: true, ptsd: true, neurodevelopmental: true, psychiatric: true,
            fertility: true, pregnant: true, birth: true, smoker: true, alcohol: true, drug: true,
            injury: true, injury_note: 'hamstring tear 6 weeks back', medication: true, medication_note: 'xanax and beta-blockers only',
            none: false, 
            contact_first_name: 'contactfirstname', contact_last_name: 'contactlastname', contact_relationship: 'husband', contact_phone_raw: '9123456788',
            terms_and_conditions: true,
            payment_policy: true,
            privacy_policy: true,
            indemnity: true
           } } }
    end
    client = Client.last
    declaration = client.declaration

    assert_equal client.account.email, client.email
    assert_equal 'Uniquefirstname', client.first_name
    assert_equal 'Uniquelastname', client.last_name
    assert_equal Date.parse('17 Feb 1985'), client.dob
    assert_equal 'female', client.gender
    assert_equal 'unique@gmail.com', client.email
    assert_equal '+911234567891', client.whatsapp
    assert_equal '+919123456789', client.phone
    assert_equal '#myinsta', client.instagram
    assert declaration.heart_trouble
    assert declaration.chest_pain_activity
    assert declaration.chest_pain_no_activity
    assert declaration.dizziness
    assert declaration.drugs
    assert declaration.doctors_permit
    assert declaration.pain
    assert declaration.fracture
    assert declaration.joint
    assert declaration.ligament
    assert declaration.tendon
    assert declaration.muscle
    assert declaration.skeletal
    assert declaration.osteoarthritis
    assert declaration.prolapse
    assert declaration.hernia
    assert declaration.postnatal
    assert declaration.diabetes
    assert declaration.cardiovascular
    assert declaration.respiratory
    assert declaration.digestive
    assert declaration.blood
    assert declaration.autoimmune
    assert declaration.nutrient
    assert declaration.hormonal
    assert declaration.endocrine
    assert declaration.migraine
    assert declaration.allergies
    assert declaration.pcos
    assert declaration.menopause
    assert declaration.gynaecological
    assert declaration.epilepsy
    assert declaration.sight
    assert declaration.kidney
    assert declaration.cancer
    assert declaration.eating
    assert declaration.depression
    assert declaration.anxiety
    assert declaration.ptsd
    assert declaration.neurodevelopmental
    assert declaration.psychiatric
    assert declaration.fertility
    assert declaration.pregnant
    assert declaration.birth
    assert declaration.smoker
    assert declaration.alcohol
    assert declaration.drug
    assert declaration.injury
    assert_equal 'hamstring tear 6 weeks back', declaration.injury_note
    assert declaration.medication
    assert_equal 'xanax and beta-blockers only', declaration.medication_note
    assert_not declaration.none
    assert_equal 'Contactfirstname', declaration.contact_first_name
    assert_equal 'Contactlastname', declaration.contact_last_name
    assert_equal 'husband', declaration.contact_relationship
    assert_equal '+919123456788', declaration.contact_phone
    assert declaration.terms_and_conditions
    assert declaration.payment_policy
    assert declaration.privacy_policy
    assert declaration.indemnity
  end

end

