class Declaration < ApplicationRecord
  include SetOperations
  belongs_to :client
  has_many :declaration_updates
  before_save :uppercase_contact_names
  validates :terms_and_conditions, :payment_policy, :privacy_policy, :indemnity, presence: true
  validate :doctors_permit_check
  scope :order_by_submitted, -> { order(created_at: :desc) }
  scope :order_by_first_name, -> { joins(:client).order(:first_name, :last_name) }
  scope :order_by_last_name, -> { joins(:client).order(:last_name, :first_name) }
  scope :initial_health_issue, -> { where(none: false).or(where(doctors_permit: true)) }
  scope :has_update, -> { left_joins(:declaration_updates).where.not(declaration_updates: {declaration_id: nil}).distinct }
  scope :has_health_issue, -> { union_scope(initial_health_issue, initial_health_issue) }
  scope :name_like, ->(name) { joins(:client).where('first_name ILIKE ? OR last_name ILIKE ?', "%#{name}%", "%#{name}%") }
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