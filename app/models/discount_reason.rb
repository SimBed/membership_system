class DiscountReason < ApplicationRecord
  has_many :discounts
  validate :dont_apply_to_multiple_things

  private
    def dont_apply_to_multiple_things
      errors.add(:base, 'max 1 application') if [:student, :friends_and_family, :first_package, :renewal_pre_package_expiry, :renewal_post_package_expiry, :renewal_pre_trial_expiry, :renewal_post_trial_expiry].map {|column| self.send(column)}.count(true) > 1
    end
end
