class Product < ApplicationRecord
  has_many :purchases, dependent: :destroy
  has_many :prices, dependent: :destroy
  belongs_to :workout_group
  validates :max_classes, presence: true
  validates :validity_length, presence: true
  validates :validity_unit, presence: true
  #validates :max_classes, uniqueness: { :scope => [:validity_length, :validity_unit, :workout_group_id] }
  validate :product_combo_must_be_unique
  scope :package, -> {where("max_classes > 1")}
  scope :dropin, -> {where(max_classes: 1)}
  scope :order_by_name_max_classes, -> {joins(:workout_group).order(:name, :max_classes)}

  def name
    "#{workout_group.name} #{max_classes < 1000 ? max_classes : 'U'}C:#{validity_length}#{validity_unit}"
  end

  def dropin?
    max_classes == 1
  end

  def self.full_name(wg_name, max_classes, validity_length, validity_unit, price_name)
    "#{wg_name} #{max_classes < 1000 ? max_classes : 'U'}C:#{validity_length}#{validity_unit} #{price_name}"
  end

  def current_prices
    prices.current.map {|p| p.price}.join(', ')
  end

  private

    # see comment on full_name_must_be_unique in Client model
    def product_combo_must_be_unique
      product = Product.where(["max_classes = ? and validity_length = ? and validity_unit = ? and workout_group_id = ?", max_classes, validity_length, validity_unit, workout_group_id])
      product.each do |p|
        # relevant for updates, new products won't have an id before save
        if id != product.first.id
          errors.add(:base, "This product already exists") if product.present?
          return
        end
      end
    end

end
