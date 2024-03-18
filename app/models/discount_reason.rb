class DiscountReason < ApplicationRecord
  has_many :discounts, dependent: :destroy
  validate :dont_apply_to_multiple_things
  # see table_day.rb and reformat
  # order by name with 'none' on top
  # "CASE name WHEN 'none' THEN 0 ELSE 1 END, name"
  scope :order_by_name, -> { order(Arel.sql('CASE name ' << sanitize_sql_array(['WHEN ? THEN ? ', 'None', 0]) << sanitize_sql_array(['ELSE ? END', 1]) << ', name')) }
  scope :order_by_rationale, -> { order(:rationale, :name) }
  #  don't want to be able to delete the nil discount_reason from the index of discount_reasons. This is not explicitly associated with any purchase but (the discount with the none discount_reason) is selected in the form to indicate no discount applies
  scope :unused, -> { left_joins(discounts: [:purchases]).where(purchases: { id: nil }).where.not(rationale: 'Base') }
  scope :current, -> { where(current: true) }
  scope :not_current, -> { where.not(current: true) }
  
  def name_with_rationale
    "#{name} (#{rationale[0]})"
  end

  private

  def dont_apply_to_multiple_things
    if [:student, :friends_and_family, :first_package, :renewal_pre_package_expiry, :renewal_post_package_expiry, :renewal_pre_trial_expiry,
        :renewal_post_trial_expiry].map do |column|
         send(column)
       end.count(true) > 1
      errors.add(:base, 'max 1 application')
    end
  end
end
