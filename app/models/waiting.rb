class Waiting < ApplicationRecord
  belongs_to :wkclass
  belongs_to :purchase

  def notify
  end
end
