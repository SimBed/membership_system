class User < ApplicationRecord
  has_many :rel_user_products, dependent: :destroy
  has_many :attendances, through: :rel_user_products

  def name
    "#{first_name} #{last_name}"
  end

  def product_for_class(wkclass)
    Product.find(self.rel_user_product_for_class(wkclass).product_id)
  end

  def revenue_for_class(wkclass)
    wkclass.rel_user_products.where(user_id: self.id).first.payment / self.rel_user_product_for_class(wkclass).attendance_estimate
  end

  private
    def rel_user_product_for_class(wkclass)
      wkclass.rel_user_products.where(user_id: self.id).first
    end

end
