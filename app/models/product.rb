class Product < ApplicationRecord
  include Csv
  has_many :purchases, dependent: :destroy
  has_many :prices, dependent: :destroy
  # see usage of current_price_objects in form.grouped_collection_select :price_id in view/.../purchases/_form
  # previously all prices (current and old) were available to select for a given product
  # has_many :current_price_objects, lambda { where(current: true) }, class_name: 'Price', dependent: :destroy, inverse_of: :product
  # the price is no longer explicitly selected following rearchitecture so current_price_objects is now redundant
  # has_many :current_price_objects, lambda { where('DATE(?) BETWEEN date_from AND date_until', Time.zone.now) }, class_name: 'Price', dependent: :destroy, inverse_of: :product
  # has_many :orders, dependent: :destroy
  belongs_to :workout_group
  validates :max_classes, presence: true
  validates :validity_length, presence: true
  validates :validity_unit, presence: true
  # validates :max_classes, uniqueness: { :scope => [:validity_length, :validity_unit, :workout_group_id] }
  validate :product_combo_must_be_unique
  validate :rider_cant_have_a_rider
  delegate :pt?, :groupex?, :online?, to: :workout_group
  # Client.packagee.active gives 'PG ambiguous column max classes' error unless 'products.max_classes' rather than just 'max_classes'.
  # scope :package, -> { where('products.max_classes > 1') }
  scope :package, -> { where('products.max_classes > 1') }
  scope :unlimited, -> { where(max_classes: 1000) }
  scope :dropin, -> { where(max_classes: 1) }
  scope :fixed, -> { where('max_classes between ? and ?', 2, 999) }
  # time to add a trial attribute to Product model
  scope :trial, -> { where(validity_length: 1, validity_unit: 'W', max_classes: 1000) }
  # https://docs.rubocop.org/rubocop-rails/cops_rails.html#railswherenot
  # scope :not_trial, -> { where.not(validity_length: 1, validity_unit: 'W', max_classes: 1000) }
  # scope :not_trial, -> { where.not("validity_length=? and validity_unit=? and max_classes=?", 1, 'W', 1000) }
  scope :not_trial, -> { trial.invert_where }
  # not because of implementation of invert_where in not_trial scope, reverse thae chaningin order here will give wrong result
  scope :package_not_trial, -> { not_trial.package }
  scope :order_by_name_max_classes, -> { joins(:workout_group).order('products.current desc', 'workout_groups.name', 'products.max_classes') }
  # keep 'space group' instead of just 'group' because of complications with using a special word like 'group'
  scope :space_group, -> { joins(:workout_group).where("workout_groups.name = 'Group'") }
  scope :wg_service, ->service { joins(:workout_group).where(workout_group: {service: }) } 
  # scope :space_group, -> { joins(:workout_group).where(workout_group: {service: 'group'}) } # no this isn't right. There can be many workout_groups with service = group, but only one workout_group with the name 'Group'
  # non-intuitive in the order clause. max(workout_groups.id) works where workout_groups.name (as wanted) fails
  # scope :order_by_total_count, -> { left_joins(:purchases).group(:id).order('COUNT(purchases.id) DESC') }
  scope :order_by_total_count, lambda {
                                 left_joins(:purchases, :workout_group).group(:id, :current).order('products.current desc, COUNT(purchases.id) DESC, max(workout_groups.id)')
                               }
  # scope :order_by_total_count, -> { left_joins(:purchases, :workout_group).group(:id, :current, 'workout_groups.id').order('products.current desc, workout_groups.id, COUNT(purchases.id) DESC') }
  # ongoing account removes products with zero purchases
  scope :order_by_ongoing_count, lambda {
                                   left_joins(:purchases, :workout_group).merge(Purchase.not_fully_expired).group(:id, :current).order('products.current desc, COUNT(purchases.id) DESC, max(workout_groups.id)')
                                 }
  scope :current, -> { where(current: true) }
  scope :not_current, -> { where.not(current: true) }
  scope :rider, -> { where(rider: true) }
  scope :not_rider, -> { where(rider: false) }
  scope :has_rider, -> { where(has_rider: true) }
  scope :sell_online, -> { where(sellonline: true) }
  scope :any_workout_group_of, ->(wgs) { joins(:workout_group).where(workout_group: { name: wgs }) }
  scope :during, ->period { joins(:purchases).merge(Purchase.during(period)) }

  class << self
    def count_for(service, period, limit, wg_show: true, color: true)
      color ? count_for_group_on_color(service, period, limit, wg_show) : count_for_no_group_on_color(service, period, limit)
    end

    # use this approach to discriminiate between products by classes/validity and by color 
    def count_for_group_on_color(service, period, limit, wg_show)
      during(period).wg_service(service).group('products.id').order(count_all: :desc).count
      .first(limit)
      .to_h
      .transform_keys{|key| Product.find(key).name(color_show: false, wg_show:)} # {"UC:1M"=>10, "6C:5W"=>2, "UC:3M"=>2, "8C:5W"=>1, "UC:6M"=>1, "4C:36D"=>1}
    end

    # use this approach to discriminiate between products by classes/validity only (but not by color)
    # NOTE: havent yet implemented the wg_show argument
    def count_for_no_group_on_color(service, period, limit, wg_show)
      sql = "SELECT pname, count(*) as count_all
            FROM
              (SELECT *, w.name || cast(max_classes as text) || 'C' || ' ' ||  cast(validity_length as text) || cast(validity_unit as text) as pname
              FROM products
              LEFT JOIN workout_groups w ON products.workout_group_id = w.id
              LEFT JOIN purchases p ON p.product_id = products.id
              where w.service = '#{service}'
              AND dop BETWEEN '#{period.begin}' AND '#{period.end}') x
            GROUP BY pname
            ORDER BY count_all DESC
            LIMIT '#{limit}';"
      ActiveRecord::Base.connection.exec_query(sql)
    end 

    def online_order_by_wg_classes_days
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

    def order_by_base_price
      # max of any price past or present rather than strctly base price but good enough for purpose
      Product.find_by_sql("SELECT products.*, MAX(price) as max_price
                          FROM products
                          INNER JOIN prices ON prices.product_id = products.id
                          GROUP BY products.id
                          ORDER BY current desc, max_price DESC;")
    end
  end

  # shifted to decorator as number_of_classes (remove once dealt with on shop page as well as group classes page)
  def shop_name_classes
    (max_classes < 1000 ? ActionController::Base.helpers.pluralize(max_classes, 'Class') : 'Unlimited').to_s
  end

  def shop_name_duration
    formal_unit = { D: 'Day', W: 'Week', M: 'Month' }
    ActionController::Base.helpers.pluralize(validity_length, formal_unit[validity_unit.to_sym]).to_s
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
    validity_length == 1 && validity_unit == 'W' && max_classes == 1000
  end

  def dropin?
    max_classes == 1
  end

  def product_type
    return :unlimited_package if unlimited_package?
    return :fixed_package if fixed_package?
    return :trial if trial?

    :dropin if dropin?
  end

  def product_style
    return :pt if pt?

    :group
  end

  def duration
    validity_unit_hash = { 'D' => :days, 'W' => :weeks, 'M' => :months }
    validity_length.send(validity_unit_hash[validity_unit])
  end

  def renewal_price(purpose)
    return nil unless purpose == 'base' || workout_group.name == 'Group'

    renewal_price = prices.where(purpose => true).where(current: true).first
    base_price = prices.where(base: true).where(current: true).first
    renewal_price || base_price
  end

  def base_price_at(date)
    prices.base_at(date).first
  end

  # not directly used
  def ongoing_count
    # Purchase.joins(:product).not_fully_expired.map{|p| p.name}.tally[name]
    Purchase.not_fully_expired.where(product_id: id).size
  end

  def deletable?
    return true if purchases.empty? && prices.empty?

    false
  end

  def editable?
    # this boils down to the same as deletable? as new records won't yet have purchases or prices, but retain for now for clarity
    return true if new_record? || deletable?

    false
  end

  Formal_unit = { D: 'Day', W: 'Week', M: 'Month' }
  # https://stackoverflow.com/questions/6806473/is-there-a-way-to-use-pluralize-inside-a-model-rather-than-a-view
  # https://stackoverflow.com/questions/10522414/breaking-up-long-strings-on-multiple-lines-in-ruby-without-stripping-newlines  
  def name(verbose: false, color_show: true, rider_show: false, wg_show: true)
    name_part = []
    name_part[0] = "#{workout_group.name} " if wg_show
    name_part[1] = verbose ? '- ' : ''
    name_part[2] = if verbose
      "#{max_classes < 1000 ? ActionController::Base.helpers.pluralize(max_classes, 'Class') : 'Unlimited Classes'} " \
      "#{ActionController::Base.helpers.pluralize(validity_length, Formal_unit[validity_unit.to_sym])}"
    else
      "#{max_classes < 1000 ? max_classes : 'U'}C:#{validity_length}#{validity_unit.to_sym}"
    end
    name_part[3] = rider_show && has_rider? ? (verbose ? ' (+Rider)' : '+R') : ''
    name_part[4] = color_show && color ? "#{' ('.concat(color, ')')}" : ''
    name_part.join
  end

  private

  # see comment on full_name_must_be_unique in Client model
  def product_combo_must_be_unique
    # https://stackoverflow.com/questions/77931145/how-to-use-activerecord-where-method-with-an-array-argument-and-nil-condition
    # product = Product.where(['max_classes = ? and validity_length = ? and validity_unit = ? and color = ? and workout_group_id = ?',
    #                          max_classes, validity_length, validity_unit, color, workout_group_id]).first
    product = Product.where(max_classes: max_classes, validity_length: validity_length, color: color, workout_group_id: workout_group_id, has_rider: has_rider).first
    return if product.blank?

    # relevant for updates, new products won't have an id before save
    errors.add(:base, 'This product already exists') unless id == product.id
  end

  def rider_cant_have_a_rider
    return unless rider? && has_rider?

    errors.add(:base, "A rider can't itself have a rider")
  end
end