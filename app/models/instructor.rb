class Instructor < ApplicationRecord
  include WhatsappNumber
  has_many :wkclasses
  has_many :instructor_rates, dependent: :destroy
  belongs_to :account, optional: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :first_name, uniqueness: { scope: :last_name, message: 'Already an instructor with this name' }
  scope :order_by_name, -> { order(:first_name, :last_name) }
  scope :order_by_current, -> { order(current: :desc) }
  scope :current, -> { where(current: true) }
  scope :not_current, -> { where.not(current: true) }
  scope :has_rate, -> { joins(:instructor_rates).distinct }
  # scope :group_rates, -> { joins(:instructor_rates).where(instructor_rates: { group: true }) }
  # scope :pt_rates, -> { joins(:instructor_rates).where(instructor_rates: { group: false }) }
  with_options if: :whatsapp_raw do
    phony_normalize :whatsapp_raw, as: :whatsapp, default_country_code: :whatsapp_country_code
  end

  validates :whatsapp, phony_plausible: true

  attr_accessor :whatsapp_country_code, :whatsapp_raw

  def name
    "#{first_name} #{last_name}"
  end

  def current_rate
    instructor_rates.current.order_recent_first.first&.rate
  end

  def group_rates
    instructor_rates.where(group: true)
  end

  def pt_rates
    instructor_rates.where(group: false)
  end

  def initials
    name.split().map(&:first).join
  end

  # make dry same code used in client method
  def country_code(number = :whatsapp)
    return '+91' unless Phony.plausible?(send(number))

    "+#{PhonyRails.country_code_from_number(send(number))}"
  end

  def country(number = :phone)
    stored_number = send(number)
    return 'IN' unless Phony.plausible?(stored_number)

    # A bunch of countries use +1 like AG, VI etc...
    return 'US' if send(:country_code, number) == '+1'

    PhonyRails.country_from_number(stored_number)
  end

  def number_raw(number = :phone)
    stored_number = send(number)
    return stored_number unless Phony.plausible?(stored_number)

    stored_number.gsub(send(:country_code, number), '')
  end
end
