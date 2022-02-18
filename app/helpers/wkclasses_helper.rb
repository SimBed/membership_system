module WkclassesHelper
  class ActiveRecord::Relation
    def next_item(item)
       item_index = self.pluck(:id).index(item)
       return self[0] if item_index == self.size - 1
       self[item_index + 1]
    end
    def prev_item(item)
       item_index = self.pluck(:id).index(item)
       return self[self.size - 1] if item_index.zero?
       self[item_index - 1]
    end
  end
end
