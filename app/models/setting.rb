# https://github.com/huacnlee/rails-settings-cached
class Setting < RailsSettings::Base
  # cache_prefix { 'v1' }

  scope :account do
    field :password_length, type: :integer, default: 6
    field :daily_account_limit, type: :integer, default: 0
    field :daily_account_limit_triggered, type: :boolean, default: false
  end
    
  scope :blast do
    field :max_recipient_blast_limit, type: :integer, default: 100    
  end

  scope :booking do
    field :amendment_count, type: :integer, default: 3
    field :visibility_window_hours_before, type: :integer, default: 2
    field :visibility_window_days_ahead, type: :integer, default: 6
    field :booking_window_days_before, type: :integer, default: 2
    field :booking_window_minutes_before, type: :integer, default: -5
    field :cancellation_window, type: :integer, default: 2
    # field :package_expiry_message_days, default: 3, validates: { presence: true, numericality: { only_integer: true } }
    # field :trial_expiry_message_days, default: 2, validates: { presence: true, numericality: { only_integer: true } }
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
  
  scope :client do
    field :cold, type: :integer, default: 3
    field :recently_attended, type: :integer, default: 3
    # field :pre_expiry_trial_renewal, type: :integer, default: 0
    # field :days_remain, type: :integer, default: 14
    # field :atendances_remain, type: :integer, default: 4
  end

  scope :marker do
    field :strength_markers, type: :array, default: ['Back Squat', 'BarBell Strict Press', 'Pull Ups', 'DB Incline Bench Row', 'Hang Power Snatch', 'Deadlift', 'Bar Dip']
    field :body_markers, type: :array, default: ['Neck', 'Chest', 'Lower Chest', 'Waist', 'Low Waist', 'Hips', 'Thigh (R)', 'Thigh (L)', 'Calf (R)', 'Calf (L)', 'Biceps (R)', 'Biceps (L)']
  end
  
  scope :discount do
    field :discount_reason_names, type: :array, default: ['Buddy', 'Class Pass', 'Complimentary', 'Fitternity', 'Friends & Family', 'Student', 'First Package',
    'Renewal of Package Before Expiry', 'Renewal of Package After Expiry', 'Renewal of Trial Before Expiry', 'Renewal of Trial After Expiry']
  end
  
  scope :modification do
    field :freeze_min_duration, type: :integer, default: 3
    field :freeze_duration_days, type: :integer, default: 14
    field :freeze_charge, type: :integer, default: 650
    field :restart_min_charge, type: :integer, default: 1500
    field :transfer_fixed_charge, type: :integer, default: 2500
  end
  
  scope :pagination do
    field :clients_pagination, type: :integer, default: 50
    field :purchases_pagination, type: :integer, default: 20
    field :wkclasses_pagination, type: :integer, default: 100
  end
  
  scope :product do
    field :product_colors, type: :array, default: ['none', 'coach tier1', 'coach tier2', 'coach tier3', 'senior coach', 'head coach', 'founder']
  end
  
  # https://github.com/huacnlee/rails-settings-cached/issues/231
  scope :purchase do
    field :payment_methods, type: :array,
    default: ['Card-Credit', 'Card-Debit', 'Cash', 'Cheque', 'ClassPass', 'Fitternity', 'Google Pay', 'Instamojo', 'NEFT', 'Not applicable', 'Not paid', 'Paid to instructor', 'PayTM', 'Razorpay', 'Restart']
    field :sunset_limit_days, type: :hash, default: {
      'week_or_less' => 30,
      'month_or_more' => 180
    }
  end
  
  scope :renewal do
    field :days_remain, type: :integer, default: 14
    field :atendances_remain, type: :integer, default: 4
  end

  scope :timetable do
    field :timetable, type: :integer, default: 1
    field :studios, type: :array, default: %w[Cellar Window Den]
    field :levels, type: :array, default: ['Beginner Friendly', 'All Levels', 'Intermediate']
    field :goals, type: :array, default: ['Hypertrophy', 'Foundations', 'HIIT & Core']
    field :durations, type: :array, default: [60, 45, 90]
  end
  
  scope :wkclass do
    field :problematic_duration, type: :integer, default: 2
  end
  
  scope :workout do
    field :styles, type: :array, default: ['Progressive Strength Training']
    field :warnings, type: :array, default: ['No teaching or coach supervision']
  end  
  
end
