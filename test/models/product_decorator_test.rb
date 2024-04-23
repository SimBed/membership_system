require 'test_helper'
include ApplicationHelper

# TODO
class ProductDecoratorTest < ActiveSupport::TestCase
  def setup
    @product_pt = products(:pt_head_coach)
    @product_pt_decorator = decorate(@product_pt)
  end
end