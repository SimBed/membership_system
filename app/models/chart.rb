class Chart
# HACK: for timezone issue with groupdata https://github.com/ankane/groupdate/issues/66  
# Using blocks for transactions - pickaxe p72 (treating a charting as a 'transaction' as it must always start with a timezone reset and end with a timezone reset). Good practise for yielding to a block.
  def self.set_timezone_and_process(*args)
    ActiveRecord.default_timezone = :utc
    # Purchase.default_timezone = :utc
    data = yield
    ActiveRecord.default_timezone = :local
    data
    # Purchase.default_timezone = :local
  end

  def self.purchase_wg_sort_order
    sort_order = %w[Group Space\ PT Apoorv\ PT Gigi\ PT]
    [sort_order.each_with_index.to_h, sort_order.length + 1]
  end  
end