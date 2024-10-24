class Discount < ApplicationRecord
  has_many :discount_assignments, dependent: :destroy
  has_many :purchases, through: :discount_assignments
  belongs_to :discount_reason
  validates :percent, presence: true, numericality: { only_integer: false, in: (0..100) }
  validates :fixed, presence: true, numericality: { only_integer: true }
  delegate :name, :rationale, to: :discount_reason
  scope :by_rationale, ->(rationale) { joins(:discount_reason).where(discount_reason: { rationale: }) }
  scope :with_rationale_at, ->(rationale, date) { joins(:discount_reason).where('DATE(?) BETWEEN start_date AND end_date', date).where(discount_reason: { rationale: }) }
  scope :with_renewal_rationale_at, lambda { |renewal_rationale, date|
                                      joins(:discount_reason).where('DATE(?) BETWEEN start_date AND end_date', date).where(discount_reason: { renewal_rationale => true })
                                    }
  scope :student_at, ->(date) { joins(:discount_reason).where('DATE(?) BETWEEN start_date AND end_date', date).where(discount_reason: { student: true }) }
  scope :friends_and_family_at, lambda { |date|
                                  joins(:discount_reason).where('DATE(?) BETWEEN start_date AND end_date', date).where(discount_reason: { friends_and_family: true })
                                }
  scope :current, ->(date) { where('DATE(?) BETWEEN start_date AND end_date', date) }
  scope :not_current, ->(date) { where('DATE(?) NOT BETWEEN start_date AND end_date', date) }
  # left_joins not joins else we lose the discounts with zero assignments so these discounts wouldn't appear in the discounts table, which would be very confusing
  scope :counted, -> { left_joins(:discount_assignments).select('discounts.*, count(discount_assignments.id) AS da_count').group('discounts.id') }

  # def self.daco
  #   # sql = "select d.*, count(da.id) as da_count FROM discounts d INNER JOIN discount_assignments da ON da.discount_id=d.id GROUP BY d.id;"
  #   # ActiveRecord::Base.connection.exec_query(sql)
  #   Discount.joins(:discount_assignments).select("discounts.*", 'count("discount_assignments.id") AS daco').group('discounts.id')
  # end

  # def self.daco2
  #   sql = "select d.*, count(da.id) as da_count FROM discounts d INNER JOIN discount_assignments da ON da.discount_id=d.id GROUP BY d.id;"
  #   ActiveRecord::Base.connection.exec_query(sql)
  # end

  def current?
    Time.zone.now.between?(start_date, end_date)
  end

  def self.rate(date)
    { first_package: with_renewal_rationale_at(:first_package, date).first.get_percent_and_fixed,
      renewal_pre_package_expiry: with_renewal_rationale_at(:renewal_pre_package_expiry, date)&.first&.get_percent_and_fixed,
      renewal_post_package_expiry: with_renewal_rationale_at(:renewal_post_package_expiry, date)&.first&.get_percent_and_fixed,
      renewal_pre_trial_expiry: with_renewal_rationale_at(:renewal_pre_trial_expiry, date)&.first&.get_percent_and_fixed,
      renewal_post_trial_expiry: with_renewal_rationale_at(:renewal_post_trial_expiry, date)&.first&.get_percent_and_fixed,
      student: student_at(date)&.first&.get_percent_and_fixed }
  end

  def get_percent_and_fixed
    { percent:, fixed: }
  end

  def no_discount?
    percent.zero? && fixed.zero?
  end

  def used?
    !DiscountAssignment.where(discount_id: id).empty?
  end

  def renewal_rationale?
    rationale == 'Renewal'
  end
end
