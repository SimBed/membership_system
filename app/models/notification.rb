class Notification < ApplicationRecord
  belongs_to :account
  belongs_to :announcement
  scope :unread, ->{ where(read_at: nil) }
  # https://stackoverflow.com/questions/5520628/rails-sort-nils-to-the-end-of-a-scope (releated but not exactly what is needed)
  # false will be on top in an ascending sort. So most recently created unread notification is on top.
  scope :order_by_date, -> { order(Arel.sql('case when read_at is null then false else true end'), created_at: :desc ) }
end
