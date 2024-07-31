class DiscountHeadingPresenter < BasePresenter

  def initialize(total, count)
    @count = count
    @total = total
  end

  def reason
    @total > 1 ? "Discount (#{@count + 1}) Reason" : 'Discount Reason' 
  end  
  
end