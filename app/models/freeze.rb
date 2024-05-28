class Freeze < ApplicationRecord
  belongs_to :purchase
  has_one :payment, as: :payable, dependent: :destroy
  accepts_nested_attributes_for :payment, reject_if: :new_and_non_chargeable?
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :duration_length
  # validate :no_attendance_during
  scope :order_by_start_date, -> {order(start_date: :asc)}
  scope :order_by_start_date_desc, -> {order(start_date: :desc)}
  scope :paid_during, ->(period) { joins(:payment).where(payments: {dop: period}) }
  scope :payment_sum, ->(period) { paid_during(period).sum(:amount)}
  scope :start_during, ->(period) { where(start_date: period) }
  scope :recover_order, ->(ids) { where(id: ids).order(Arel.sql("POSITION(id::TEXT IN '#{ids.join(',')}')")) }

  def duration
    # (end_date - start_date + 1.days).to_i #Date - Date returns a rational
    # .. inclusive, ... exclusive
    (start_date..end_date).count
  end

  # use for manually automating bulk freezes over holidays
  def applies_during(period)
    (start_date..end_date).overlaps?(period)
  end

  def days_frozen
    return 0 if Time.zone.now < start_date

    return (end_date - start_date + 1).to_i if Time.zone.now > end_date

    (Time.zone.now.to_date - start_date).to_i
  end

  private

  def duration_length
    errors.add(:base, "must be #{Setting.freeze_min_duration} days or more") if duration < Setting.freeze_min_duration
  end

  def new_and_non_chargeable?(att)
    # on update of chargeable to non-chargeable, there will already be a payment created, which we want to be updated to zero. (We could also delete the payment in the controller if we wished)
    # for a new freeze, if it is non-chargeable, don't creaate a payment
    return false unless new_record? 

    att[:amount].nil? || att[:amount].to_i.zero? 
  end  

end
