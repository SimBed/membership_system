# https://github.com/huacnlee/rails-settings-cached
class Setting < RailsSettings::Base
  cache_prefix { 'v1' }

  scope :application do
    # field :whitelist, type: :array, default: %w[nishaap trivedi james@t riyajha]
    field :renew_online, type: :boolean, default: false
    field :password_length, type: :integer, default: 6
    field :gst_rate, type: :integer, default: 18
  end

  scope :timetable do
    field :timetable, type: :integer, default: 1
    field :studios, type: :array, default: %w[Cellar Window Den]
    field :levels, type: :array, default: ['Beginner Friendly', 'All Levels', 'Intermediate']
    field :goals, type: :array, default: ['Hypertrophy', 'Foundations', 'HIIT & Core']
  end

  scope :discount do
    field :discount_names, type: :array, default: ['Buddy', 'Class Pass', 'Complimentary', 'Fitternity', 'Friends & Family', 'Student', 'First Package',
                                                   'Renewal of Package Before Expiry', 'Renewal of Package After Expiry', 'Renewal of Trial Before Expiry', 'Renewal of Trial After Expiry']
  end

  scope :product do
    field :product_colors, type: :array, default: ['none', 'coach tier1', 'coach tier2', 'coach tier3', 'senior coach', 'head coach', 'founder']
  end

  scope :wkclassmaker do
    field :classmaker_advance, type: :integer, default: 4
  end

  scope :renewal do
    # field :pre_expiry_package_renewal, type: :integer, default: 0
    # field :post_expiry_trial_renewal, type: :integer, default: 0
    # field :pre_expiry_trial_renewal, type: :integer, default: 0
    field :days_remain, type: :integer, default: 14
    field :attendances_remain, type: :integer, default: 4
  end

  scope :client do
    field :cold, type: :integer, default: 3
    field :recently_attended, type: :integer, default: 3
    field :pre_expiry_trial_renewal, type: :integer, default: 0
    field :days_remain, type: :integer, default: 14
    field :attendances_remain, type: :integer, default: 4
  end

  scope :pagination do
    field :clients_pagination, type: :integer, default: 50
    field :purchases_pagination, type: :integer, default: 20
    field :wkclasses_pagination, type: :integer, default: 100
  end

  scope :attendance do
    field :amendment_count, type: :integer, default: 3
    field :visibility_window_hours_before, type: :integer, default: 2
    field :visibility_window_days_ahead, type: :integer, default: 6
    field :booking_window_days_before, type: :integer, default: 2
    field :booking_window_minutes_before, type: :integer, default: -5
    field :cancellation_window, type: :integer, default: 2
  end

  # https://github.com/huacnlee/rails-settings-cached/issues/231
  scope :purchase do
    field :payment_methods, type: :array, default: ['A&R conversion', 'Card-Credit', 'Card-Debit', 'Cash', 'Cheque', 'ClassPass', 'Fitternity', 'Google Pay', 'Instamojo', 'NEFT', 'Not applicable', 'Not paid', 'Paid to instructor', 'PayTM', 'Razorpay']
    field :freeze_min_duration, type: :integer, default: 3
    field :sunset_limit_days, type: :hash, default: {
      'week_or_less' => 30,
      'month_or_more' => 180
    }
  end

  scope :booking do
    field :quotation, default: "Exercise is King. Nutrition is Queen. Put them together & you've got a Kingdom.",
                      validates: { presence: true, length: { in: 2..200 } }
    field :package_expiry_message_days, default: 3, validates: { presence: true, numericality: { only_integer: true } }
    field :trial_expiry_message_days, default: 2, validates: { presence: true, numericality: { only_integer: true } }
    field :amnesty_limit, type: :hash, default: {
      group:
        { late_cancels:
          { unlimited_package: 2,
            fixed_package: 1,
            trial: 100,
            dropin: 0,
            penalty: { amount: 1 } },
          no_shows:
          { unlimited_package: 1,
            fixed_package: 0,
            trial: 100,
            dropin: 0,
            penalty: { amount: 2 } },
          early_cancels:
        { unlimited_package: 1000,
          fixed_package: 1000,
          trial: 1000,
          dropin: 1000,
          penalty: { amount: 1 } } },
      pt:
        { late_cancels:
          { fixed_package: 0,
            dropin: 0 },
          no_shows:
            { fixed_package: 0,
              dropin: 0 },
          early_cancels:
            { fixed_package: 1000,
              dropin: 1000 } }
    }
  end
end
