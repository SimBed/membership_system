class Chart
# HACK: for timezone issue with groupdata https://github.com/ankane/groupdate/issues/66  
# Using blocks for transactions - pickaxe p72 (treating a charting as a 'transaction' as it must always start with a timezone reset and end with a timezone reset). Good practise for yielding to a block.

  class << self
    def set_timezone_and_process(*args)
      ActiveRecord.default_timezone = :utc
      # Purchase.default_timezone = :utc
      data = yield
      ActiveRecord.default_timezone = :local
      data
      # Purchase.default_timezone = :local
    end

    def workout_group_order(period)
      # when creating donut charts, keeping the same order from year to year makes visual comparison easier
      Purchase.count_by_workout_group(period) # {"Group"=>17, "Nutrition"=>1, "Space PT"=>1}
      .keys # ["Group", "Nutrition", "Space PT"]
      .each_with_index # Enum
      .to_h # {"Group"=>0, "Nutrition"=>1, "Space PT"=>2} 
    end  

    def product_order(service, period, limit)
      Product.count_for_service_purchased_during(service, period, limit) # {"UC:1M"=>10, "6C:5W"=>2, "UC:3M"=>2, "8C:5W"=>1, "UC:6M"=>1, "4C:36D"=>1}
      .keys
      .each_with_index
      .to_h # {"UC:1M"=>0, "6C:5W"=>1, "UC:3M"=>2, "8C:5W"=>3, "UC:6M"=>4, "4C:36D"=>5}
    end
  end

end