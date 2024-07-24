class ShopProductDecorator < BaseDecorator
  # https://stackoverflow.com/questions/6806473/is-there-a-way-to-use-pluralize-inside-a-model-rather-than-a-view
  include ActionView::Helpers::TextHelper
  include ApplyDiscount
  # this gives undefined method `rupees' for ApplicationHelper:Module
  # delegate :rupees, to: 'ApplicationHelper'
  delegate :name, to: :workout_group, prefix: true
  # equiv to:
  # def workout_group_name
  #   workout_group.name
  # end

  def class_number_type
    product_type.to_s.split('_').first
  end

  def number_of_classes
    (max_classes < 1000 ? pluralize(max_classes, 'Class') : 'Unlimited').to_s
  end

  def duration_text
    pluralize(validity_length, formal_unit)
  end

  def price
    apply_discount(base_price_at(Time.zone.now), Discount.with_renewal_rationale_at('first_package', Time.zone.now)&.first)
  end

  def base_price
    base_price_at(Time.zone.now).price
  end

  def base_price_rupees
    rupees(base_price)
  end

  def discount
    return nil if base_price == price

    base_price - price
  end

  def saving
    return nil if discount.nil?

    content_tag(:li, "Save #{rupees(discount)}")
  end

  def freeze_charge_link
    # https://guides.rubyonrails.org/i18n.html#bulk-and-namespace-lookup
    text = I18n.t(['.freeze_charge_link0', '.freeze_charge_link1', '.freeze_charge_link2'])
    content_tag(:li,
                "#{text[0]} #{link_to text[1], charges_and_deductions_path, class: %w[fw-bolder text-decoration-underline], target: '_blank', rel: 'noopener'}
                 #{text[2]} #{link_to text[1], terms_and_conditions_path, class: %w[fw-bolder text-decoration-underline], target: '_blank', rel: 'noopener'}".html_safe)
  end
end
