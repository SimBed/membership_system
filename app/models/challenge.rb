class Challenge < ApplicationRecord
  has_many :achievements, dependent: :destroy
  has_many :clients, through: :achievements
  has_many :sub_challenges, class_name: 'Challenge'
  belongs_to :main_challenge, class_name: 'Challenge', foreign_key: 'challenge_id', optional: true
  validates :name, presence: true, length: {maximum: 30}, uniqueness: {case_sensitive: false}
  validates :metric, presence: true, length: {maximum: 10}
  validates :metric_type, presence: true, length: {maximum: 10}
  scope :order_by_date, -> { order(created_at: :desc) }
  scope :order_by_name, -> { order(:name) }

  
  def positions
    if has_sub_challenges?
      sub_challenges.map { |c| c.positions}
                    .map {|r| r.to_a} # array of array of hashes[ [...], [{"id"=>41, "first_name"=>"Anne", "max_score"=>3850}, {"id"=>209, "first_name"=>"Aakash", "max_score"=>2500}],...]
                    .flatten.group_by {|r| r['id']} # hash (values are array of hashes) {41=>[{"id"=>41, "first_name"=>"Anne", "max_score"=>3901}, {"id"=>41, "first_name"=>"Anne", "max_score"=>3850}], 209=>[...],...}
                    .map { |key, value| value.reduce { |acc, h| (acc || {}).merge(h) { |key, oldval, newval| key=='max_score' ? (oldval + newval) : oldval } }} # reduce the array of hashes to a single hash
                    .sort_by {|h| -h['max_score']} 
    else
      positions_sub_challenge
    end
  end
  
  def positions_sub_challenge
    sql = "SELECT clients.id, clients.first_name, max(achievements.score) as max_score
          FROM clients
          INNER JOIN achievements on clients.id = achievements.client_id
          INNER JOIN challenges on achievements.challenge_id = challenges.id
          WHERE challenges.id = #{self.id}
          GROUP BY clients.id
          ORDER BY max_score DESC;"
        
      ActiveRecord::Base.connection.exec_query(sql)
  end

  def has_sub_challenges?
    return true unless sub_challenges.empty?

    false
  end


  def positions_for_main
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