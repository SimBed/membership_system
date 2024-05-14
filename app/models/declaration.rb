class Declaration < ApplicationRecord
  belongs_to :client
  before_save :uppercase_contact_names
  validates :terms_and_conditions, :payment_policy, :privacy_policy, :indemnity, presence: true
  validate :doctors_permit_check
  scope :order_by_date, -> { order(:created_at) }
  attr_accessor :contact_phone_raw, :contact_phone_country_code
  with_options if: :contact_phone_raw do
    phony_normalize :contact_phone_raw, as: :contact_phone, default_country_code: 'IN'
  end

  private

  # make dry, same method shared with client
  def uppercase_contact_names
    self.contact_first_name = contact_first_name&.strip&.titleize
    self.contact_last_name = contact_last_name&.strip&.titleize
  end

  def doctors_permit_check
    return if doctors_permit?

    return if [heart_trouble?, chest_pain_activity?, chest_pain_no_activity?, dizziness?, drugs?].none?

    errors.add(:base, "Doctor's clearance needed")
  end
end