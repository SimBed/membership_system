class Partner < ApplicationRecord
  include WhatsappNumber
  has_many :workout_groups
  belongs_to :account, optional: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :first_name, uniqueness: { scope: :last_name, message: 'Already a partner with this name' }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, allow_blank: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :account, presence: true, if: :account_id
  scope :order_by_name, -> { order(:first_name, :last_name) }

  def name
    "#{first_name} #{last_name}"
  end

  def workout_group_list
    workout_groups.pluck(:name).join(', ')
  end
end
