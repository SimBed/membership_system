class Client < ApplicationRecord
  has_many :purchases, dependent: :destroy
  has_many :attendances, through: :purchases
  scope :order_by_name, -> { order(:first_name, :last_name) }

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

end
