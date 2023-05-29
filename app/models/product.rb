class Product < ApplicationRecord
  include Csv
  has_many :purchases, dependent: :destroy
  has_many :prices, dependent: :destroy
  # see usage of current_price_objects in form.grouped_collection_select :price_id in view/.../purchases/_form
  # previously all prices (current and old) were available to select for a given product
  # has_many :current_price_objects, lambda { where(current: true) }, class_name: 'Price', dependent: :destroy, inverse_of: :product
  # the price is no longer explicitly selected following rearchitecture so current_price_objects is now redundant
  # has_many :current_price_objects, lambda { where('DATE(?) BETWEEN date_from AND date_until', Time.zone.now) }, class_name: 'Price', dependent: :destroy, inverse_of: :product
  has_many :orders
  belongs_to :workout_group
  validates :max_classes, presence: true
  validates :validity_length, presence: true
  validates :validity_unit, presence: true
  # validates :max_classes, uniqueness: { :scope => [:validity_length, :validity_unit, :workout_group_id] }
  validate :product_combo_must_be_unique
  delegate :pt?, :groupex?, :online?, to: :workout_group
  # Client.packagee.active gives 'PG ambiguous column max classes' error unless 'products.max_classes' rather than just 'max_classes'.
  # scope :package, -> { where('products.max_classes > 1') }
  scope :package, -> { where('products.max_classes > 1') }
  scope :unlimited, -> { where(max_classes: 1000) }
  scope :dropin, -> { where(max_classes: 1) }
  scope :fixed, -> { where('max_classes between ? and ?', 2, 999) }
  scope :trial, -> { where(validity_length: 1, validity_unit: 'W') }
  scope :not_trial, -> { where.not(validity_length: 1, validity_unit: 'W') }
  scope :package_not_trial, -> { package.not_trial }
  scope :order_by_name_max_classes, -> { joins(:workout_group).order('products.current desc', 'workout_groups.name', :max_classes) }
  scope :space_group, -> { joins(:workout_group).where("workout_groups.name = 'Group'") }
  # non-intuitive in the order clause. max(workout_groups.id) works where workout_groups.name (as wanted) fails
  # scope :order_by_total_count, -> { left_joins(:purchases).group(:id).order('COUNT(purchases.id) DESC') }
  scope :order_by_total_count, -> { left_joins(:purchases, :workout_group).group(:id, :current).order('products.current desc, COUNT(purchases.id) DESC, max(workout_groups.id)') }
  # scope :order_by_total_count, -> { left_joins(:purchases, :workout_group).group(:id, :current, 'workout_groups.id').order('products.current desc, workout_groups.id, COUNT(purchases.id) DESC') }
  # ongoing account removes products with zero purchases
  scope :order_by_ongoing_count, -> { left_joins(:purchases, :workout_group).merge(Purchase.not_fully_expired).group(:id, :current).order('products.current desc, COUNT(purchases.id) DESC, max(workout_groups.id)') }
  scope :current, -> { where(current: true) }

  def self.online_order_by_wg_classes_days
    # https://stackoverflow.com/questions/39981636/rails-find-by-sql-uses-the-wrong-id    
    Product.find_by_sql("SELECT products.*, CASE
                                    WHEN validity_unit = 'M' THEN validity_length * 30
                                    WHEN validity_unit = 'W' THEN validity_length * 7
                                    ELSE validity_length * 1 END 
                                    AS days
                        FROM products
                        INNER JOIN workout_groups w ON products.workout_group_id = w.id
                        WHERE max_classes > 1 AND sellonline = true
                        ORDER BY current desc, name, max_classes, days;")
  end

  def self.order_by_base_price
    # max of any price past or present rather than strctly base price but good enough for purpose
    Product.find_by_sql("SELECT products.*, MAX(price) as max_price
                        FROM products
                        INNER JOIN prices ON prices.product_id = products.id
                        GROUP BY products.id
                        ORDER BY current desc, max_price DESC;")
  end

  def css_class
    max_classes < 1000 ? 'fixed' : 'unlimited' 
  end
    
  def name
    "#{workout_group.name} #{max_classes < 1000 ? max_classes : 'U'}C:#{validity_length}#{validity_unit.to_sym}#{' ('.concat(color,')') unless color.nil?}"
  end

  # https://stackoverflow.com/questions/6806473/is-there-a-way-to-use-pluralize-inside-a-model-rather-than-a-view
  # https://stackoverflow.com/questions/10522414/breaking-up-long-strings-on-multiple-lines-in-ruby-without-stripping-newlines
  def formal_name
    formal_unit = { D: 'Day', W: 'Week', M: 'Month' }
    "#{workout_group.name} - " \
      "#{max_classes < 1000 ? ActionController::Base.helpers.pluralize(max_classes, 'Class') : 'Unlimited Classes'} " \
      "#{ActionController::Base.helpers.pluralize(validity_length, formal_unit[validity_unit.to_sym])}#{' ('.concat(color,')') unless color.nil?}"
  end

  def shop_name_classes
      "#{max_classes < 1000 ? ActionController::Base.helpers.pluralize(max_classes, 'Class') : 'Unlimited'}"
  end  

  def shop_name_duration
    formal_unit = { D: 'Day', W: 'Week', M: 'Month' }
      "#{ActionController::Base.helpers.pluralize(validity_length, formal_unit[validity_unit.to_sym])}"
  end

  def formal_unit
    { D: 'Day', W: 'Week', M: 'Month' }[validity_unit.to_sym]
  end  

  def unlimited_package?
    max_classes == 1000 && !trial?
  end

  def fixed_package?
    max_classes.between?(2, 999)
  end

  def trial?
    validity_length == 1 && validity_unit == 'W'
  end

  def dropin?
    max_classes == 1
  end

  # def pt?
  #   'PT'.in? workout_group.name
  # end

  def product_type
    return :unlimited_package if unlimited_package?
    return :fixed_package if fixed_package?
    return :trial if trial?
    return :dropin if dropin?
  end

  def product_style
    return :pt if pt?

    :group
  end

  #seems to be named misleadingly. Rename to duration? and test
  def duration_days
    validity_unit_hash = { 'D' => :days, 'W' => :weeks, 'M' => :months }
    validity_length.send(validity_unit_hash[validity_unit])
  end

  # for revenue cashflows
  # probably no unlimited products with days but assume every day if so
  def attendance_estimate
    return max_classes unless max_classes == 1000

    times_per_unit_hash = { 'D' => 1, 'W' => 6, 'M' => 20 }
    return validity_length * times_per_unit_hash[validity_unit] unless "#{validity_length}#{validity_unit}" == '1M'

    25 # for 1M
  end

  def self.full_name(wg_name, max_classes, validity_length, validity_unit, price_name)
    "#{wg_name} #{max_classes < 1000 ? max_classes : 'U'}C:#{validity_length}#{validity_unit} #{price_name}"
  end

  # no longer used
  # def current_prices
  #   prices.current.map(&:price).join(', ')
  # end

  # def renewal_price(price_name)
  #   renewal_price = prices.where(name: price_name).where(current: true)&.first
  #   base_price = prices.where(name: 'Base').where(current: true).first
  #
  #   renewal_price || base_price
  #
  # end

  # must make workout_group.name == 'Group' flexible
  # def renewal_price(purpose)
  #   return nil unless purpose == 'base' || workout_group.name == 'Group'
    
  #   renewal_price = prices.where(purpose => true).where(current: true).first
  #   base_price = prices.where(base: true).where(current: true).first
  #   renewal_price || base_price
  # end

  def renewal_price(purpose)
    return nil unless purpose == 'base' || workout_group.name == 'Group'
    
    renewal_price = prices.where(purpose => true).where(current: true).first
    base_price = prices.where(base: true).where(current: true).first
    renewal_price || base_price
  end

  # def base_price
  #   prices.current.base.first
  # end

  def base_price_at(date)
    prices.base_at(date).first
  end

  def ongoing_count # not directly used
    # Purchase.joins(:product).not_fully_expired.map{|p| p.name}.tally[name]
    Purchase.not_fully_expired.where(product_id: id).size
  end

  private

  # see comment on full_name_must_be_unique in Client model
  def product_combo_must_be_unique
    product = Product.where(['max_classes = ? and validity_length = ? and validity_unit = ? and color = ? and workout_group_id = ?',
                             max_classes, validity_length, validity_unit, color, workout_group_id]).first
    return if product.blank?

    # relevant for updates, new products won't have an id before save
    errors.add(:base, 'This product already exists') unless id == product.id
  end
end
