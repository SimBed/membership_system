class DiscountReason < ApplicationRecord
  has_many :discounts, dependent: :destroy
  validate :dont_apply_to_multiple_things
  # see table_day.rb and reformat
  # order by name with 'none' on top
  # "CASE name WHEN 'none' THEN 0 ELSE 1 END, name"
  scope :order_by_name, -> { order(Arel.sql('CASE name ' <<  sanitize_sql_array(['WHEN ? THEN ? ', 'None', 0]) << sanitize_sql_array(['ELSE ? END', 1]) << ', name')) }
  scope :order_by_rationale, -> { order(:rationale, :name )}
  scope :unused, -> { left_joins(discounts: [:purchases]).where(purchases: {id:nil}).distinct }

  private
    def dont_apply_to_multiple_things
      errors.add(:base, 'max 1 application') if [:student, :friends_and_family, :first_package, :renewal_pre_package_expiry, :renewal_post_package_expiry, :renewal_pre_trial_expiry, :renewal_post_trial_expiry].map {|column| self.send(column)}.count(true) > 1
    end
end

