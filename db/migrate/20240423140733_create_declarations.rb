class CreateDeclarations < ActiveRecord::Migration[7.0]
  def change
    create_table :declarations do |t|
      t.boolean :pain
      t.boolean :fracture
      t.boolean :joint
      t.boolean :ligament
      t.boolean :tendon
      t.boolean :muscle
      t.boolean :skeletal
      t.boolean :osteoarthritis
      t.boolean :prolapse
      t.boolean :hernia
      t.boolean :postnatal
      t.boolean :diabetes
      t.boolean :cardiovascular
      t.boolean :respiratory
      t.boolean :digestive
      t.boolean :blood
      t.boolean :autoimmune
      t.boolean :nutrient
      t.boolean :hormonal
      t.boolean :endocrine
      t.boolean :migraine
      t.boolean :allergies
      t.boolean :pcos
      t.boolean :menopause
      t.boolean :gynaecological
      t.boolean :epilepsy
      t.boolean :sight
      t.boolean :kidney
      t.boolean :cancer
      t.boolean :eating
      t.boolean :depression
      t.boolean :anxiety
      t.boolean :ptsd
      t.boolean :neurodevelopmental
      t.boolean :psychiatric
      t.boolean :fertility
      t.boolean :pregnant
      t.boolean :birth
      t.boolean :smoker
      t.boolean :alcohol
      t.boolean :drug
      t.boolean :injury
      t.text :injury_note
      t.boolean :medication
      t.text :medication_note
      t.boolean :none
      t.string :contact_first_name
      t.string :contact_last_name
      t.string :contact_relationship
      t.string :contact_phone    
      t.boolean :heart_trouble
      t.boolean :chest_pain_activity
      t.boolean :chest_pain_no_activity
      t.boolean :dizziness
      t.boolean :drugs
      t.boolean :doctors_permit
      t.boolean :signed
      t.boolean :terms_and_conditions
      t.boolean :payment_policy
      t.boolean :privacy_policy
      t.boolean :indemnity
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
  end
end













