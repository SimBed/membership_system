class User < ApplicationRecord
  has_many :rel_user_products, dependent: :destroy

  def product_for_class(wkclass)
    Product.find(wkclass.rel_user_products.where(user_id: self.id).first.product_id)
  end

  def revenue_for_class(wkclass)
    wkclass.rel_user_products.where(user_id: self.id).first.payment / self.product_for_class(wkclass).max_classes
  end
end
