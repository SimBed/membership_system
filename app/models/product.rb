class Product < ApplicationRecord
  has_many :purchases, dependent: :destroy
  has_many :prices, dependent: :destroy
  belongs_to :workout_group
  #validates :max_classes, uniqueness: { :scope => [:validity_length, :validity_unit, :workout_group_id] }
  validate :product_combo_must_be_unique

  def name
    "#{workout_group.name} #{max_classes < 1000 ? max_classes : 'U'}C:#{validity_length}#{validity_unit}"
  end

  def current_prices
    prices.current.map {|p| p.price}.join(', ')
  end

  # more work needed
  def self.by_purchase_date(product_id, start_date, end_date)
      purchase_ids = Product.joins(:purchases)
                                 .where("purchases.dop BETWEEN '#{start_date}' AND '#{end_date}'")
                                 .where("products.id = ?", "#{product_id}")
                                 .select('purchases.id').to_a.map(&:id)
      Purchase.find(purchase_ids)
  end

  private

    # see comment on full_name_must_be_unique in Client model
    def product_combo_must_be_unique
      product = Product.where(["max_classes = ? and validity_length = ? and validity_unit = ? and workout_group_id = ?", max_classes, validity_length, validity_unit, workout_group_id])
      product.each do |p|
        if id != product.first.id
          errors.add(:base, "This product already exists") if product.present?
          return
        end
      end
    end

end
