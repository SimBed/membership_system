require "test_helper"

class MakeDeclarationTest < ActionDispatch::IntegrationTest
  setup do
    @account_client = accounts(:client2)
    @client = @account_client.client
  end

  test 'existing client (without declaration) making declaration (full range of health issues apply)' do

      log_in_as(@account_client)
      get new_client_declaration_path(@client)
      assert_template 'shared/declarations/new'

      assert_difference 'Declaration.count' do
        patch client_declaration_path(@client), params:
          { client:
           { dob: "1985-02-17",
             gender: 'female',           
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
      assert_redirected_to client_bookings_path(@client.id)
      declaration = @client.declaration

      assert_equal Date.parse('17 Feb 1985'), @client.reload.dob
      assert_equal 'female', @client.reload.gender
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
