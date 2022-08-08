class Product < ApplicationRecord
  include Csv  
  has_many :purchases, dependent: :destroy
  has_many :prices, dependent: :destroy
  belongs_to :workout_group
  validates :max_classes, presence: true
  validates :validity_length, presence: true
  validates :validity_unit, presence: true
  # validates :max_classes, uniqueness: { :scope => [:validity_length, :validity_unit, :workout_group_id] }
  validate :product_combo_must_be_unique
  scope :package, -> { where('max_classes > 1') }
  scope :unlimited, -> { where(max_classes: 1000) }
  scope :dropin, -> { where(max_classes: 1) }
  scope :fixed, -> { where('max_classes between ? and ?', 2, 999) }
  scope :trial, -> { where(validity_length: 1, validity_unit: 'W') }
  scope :order_by_name_max_classes, -> { joins(:workout_group).order(:name, :max_classes) }

  def name
    "#{workout_group.name} #{max_classes < 1000 ? max_classes : 'U'}C:#{validity_length}#{validity_unit.to_sym}"
  end

  # https://stackoverflow.com/questions/6806473/is-there-a-way-to-use-pluralize-inside-a-model-rather-than-a-view
  # https://stackoverflow.com/questions/10522414/breaking-up-long-strings-on-multiple-lines-in-ruby-without-stripping-newlines
  def formal_name
    formal_unit = { D: 'Day', W: 'Week', M: 'Month' }
    "#{workout_group.name} - " \
      "#{max_classes < 1000 ? ActionController::Base.helpers.pluralize(max_classes, 'Class') : 'Unlimited Classes'} " \
      "#{ActionController::Base.helpers.pluralize(validity_length, formal_unit[validity_unit.to_sym])}"
  end

  def unlimited_package?
    max_classes == 1000 && !trial?
  end

  def fixed_package?
    max_classes.between?(2, 999)
  end

  def trial?
    validity_length == 1 && validity_unit == 'W'
  end

  def dropin?
    max_classes == 1
  end

  def pt?
    'PT'.in? workout_group.name
  end

  def product_type
    return :unlimited_package if unlimited_package?
    return :fixed_package if fixed_package?
    return :trial if trial?
    return :dropin if dropin?
  end

  def duration_days
    validity_unit_hash = { 'D' => :days, 'W' => :weeks, 'M' => :months }
    validity_length.send(validity_unit_hash[validity_unit])
  end

  # for revenue cashflows
  # probably no unlimited products with days but assume every day if so
  def attendance_estimate
    return max_classes unless max_classes == 1000

    times_per_unit_hash = { 'D' => 1, 'W' => 6, 'M' => 20 }
    return validity_length * times_per_unit_hash[validity_unit] unless "#{validity_length}#{validity_unit}" == '1M'

    25 # for 1M
  end

  def self.full_name(wg_name, max_classes, validity_length, validity_unit, price_name)
    "#{wg_name} #{max_classes < 1000 ? max_classes : 'U'}C:#{validity_length}#{validity_unit} #{price_name}"
  end

  def current_prices
    prices.current.map(&:price).join(', ')
  end

  private

  # see comment on full_name_must_be_unique in Client model
  def product_combo_must_be_unique
    product = Product.where(['max_classes = ? and validity_length = ? and validity_unit = ? and workout_group_id = ?',
                             max_classes, validity_length, validity_unit, workout_group_id]).first
    return if product.blank?

    # relevant for updates, new products won't have an id before save
    errors.add(:base, 'This product already exists') unless id == product.id
  end
end
