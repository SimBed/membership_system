# https://github.com/huacnlee/rails-settings-cached
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  scope :application do
    field :whitelist, type: :array, default: %w[nishaap trivedi james@t riyajha]
    field :renew_online, type: :boolean, default: false
  end

  scope :timetable do
    field :timetable, type: :integer, default: 1
  end

  scope :wkclassmaker do
    field :classmaker_advance, type: :integer, default: 4
  end

  scope :renewal_discount do
    field :pre_expiry_package_renewal, type: :integer, default: 0
    field :post_expiry_trial_renewal, type: :integer, default: 0
    field :pre_expiry_trial_renewal, type: :integer, default: 0
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
            dropin: 1000 } } }
  end
end
