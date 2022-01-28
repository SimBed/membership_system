class Client < ApplicationRecord
  has_many :purchases, dependent: :destroy
  has_many :attendances, through: :purchases
  belongs_to :account, optional: true
  scope :order_by_name, -> { order(:first_name, :last_name) }
  # validates :first_name, uniqueness: {scope: :last_name}
  validates :first_name, presence: true
  validates :last_name, presence: true
  validate :full_name_must_be_unique
  # validates :email, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :phone, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :instagram, uniqueness: { case_sensitive: false }, allow_blank: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i.freeze
  validates :email, allow_blank: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }

  def name
    "#{first_name} #{last_name}"
  end

  def product_for_class(wkclass)
    Product.find(self.purchase_for_class(wkclass).product_id)
  end

  def revenue_for_class(wkclass)
    wkclass.purchases.where(client_id: self.id).first.payment / self.purchase_for_class(wkclass).attendance_estimate
  end

  private
    def purchase_for_class(wkclass)
      wkclass.purchases.where(client_id: self.id).first
    end

    def full_name_must_be_unique
      # complicated due to situation on update. There will of course be one record in the database
      # with the relevant name on update (the record we are updating) and we don't want its presence
      # to trigger warnings. We don't however want an exisitng record to have its name changed to
      # a name that is the same of a (different) already existing record. Note the id of a new record
      # (not yet saved) will be nil (so won't be equal to the id of any saved record.)
      client = Client.where(["first_name = ? and last_name = ?", first_name, last_name])
      client.each do |c|
        if id != client.first.id
          errors.add(:base, "Client named #{first_name} #{last_name} already exists") if client.present?
        return
        end
      end
    end
end
