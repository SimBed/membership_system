# https://github.com/huacnlee/rails-settings-cached
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  scope :application do
    field :whitelist, type: :array, default: %w[nishaap trivedi james@t riyajha]
  end

  scope :booking do
    field :quotation, default: "Exercise is King. Nutrition is Queen. Put them together & you've got a Kingdom.",
                     validates: { presence: true, length: { in: 2..200 } }
    field :package_expiry_message_days, default: 3, validates: { presence: true, numericality: { only_integer: true } }
    field :trial_expiry_message_days, default: 2, validates: { presence: true, numericality: { only_integer: true } }
    field :amnesty_limit, type: :hash, default: {
       late_cancels:
          { unlimited_package: 2,
            fixed_package: 1,
            trial: 100,
            dropin: 0,
            penalty: {amount: 1} },
        no_shows:
          { unlimited_package: 1,
            fixed_package: 0,
            trial: 100,
            dropin: 0,
            penalty: {amount: 2} },
        early_cancels:
          { unlimited_package: 1000,
            fixed_package: 1000,
            trial: 1000,
            dropin: 1000,
            penalty: {amount: 1} }
       }

  end
end
