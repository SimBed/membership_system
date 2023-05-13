class CreateDiscountReasons < ActiveRecord::Migration[6.1]
  def change
    create_table :discount_reasons do |t|
      t.string :name
      t.string :rationale
      t.boolean :student, default: false
      t.boolean :friends_and_family, default: false
      t.boolean :first_package, default: false
      t.boolean :renewal_pre_package_expiry, default: false
      t.boolean :renewal_post_package_expiry, default: false
      t.boolean :renewal_pre_trial_expiry, default: false
      t.boolean :renewal_post_trial_expiry, default: false

      t.timestamps
    end
    add_index :discount_reasons, :name
    add_index :discount_reasons, :rationale
    add_index :discount_reasons, :student
    add_index :discount_reasons, :friends_and_family
    add_index :discount_reasons, :first_package
    add_index :discount_reasons, :renewal_pre_package_expiry
    add_index :discount_reasons, :renewal_post_package_expiry
    add_index :discount_reasons, :renewal_pre_trial_expiry
    add_index :discount_reasons, :renewal_post_trial_expiry
  end
end
