class Challenge < ApplicationRecord
  has_many :achievements, dependent: :destroy
  has_many :clients, through: :achievements
  validates :name, presence: true, length: {maximum: 30}, uniqueness: {case_sensitive: false}
  validates :metric, presence: true, length: {maximum: 10}
  validates :metric_type, presence: true, length: {maximum: 10}
  scope :order_by_date, -> { order(created_at: :desc) }
  scope :order_by_name, -> { order(:name) }

  def positions
    sql = "SELECT clients.id, clients.first_name, max(achievements.score) as max_score
           FROM clients
           INNER JOIN achievements on clients.id = achievements.client_id
           INNER JOIN challenges on achievements.challenge_id = challenges.id
           WHERE challenges.id = #{self.id}
           GROUP BY clients.id
           ORDER BY max_score DESC;"
    ActiveRecord::Base.connection.exec_query(sql)
  end

end
