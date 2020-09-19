class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :teams, dependent: :destroy

  EMAIL_LENGTH = (6..50).freeze
  NAME_LENGTH = (2..15).freeze
  ROLES = %w[customer admin moderator].freeze

  enum role: ROLES

  validates :email, presence: true, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.a[a-z]+)*\.[a-z]+\z/i }, uniqueness: true
  validates :email, length: { in: EMAIL_LENGTH }
  validates :name, length: { in: NAME_LENGTH }, allow_blank: true
  validates :role, presence: true, inclusion: { in: ROLES }

  def can_moderate?
    admin? || moderator?
  end

  def active_team
    @active_team ||= teams.find_by(id: active_team_id) || teams.first
  end

  def active_league
    active_team.league
  end

  def next_round
    active_league.active_tour || active_league.tours.inactive.first
  end

  def avatar_path
    "avatars/avatar_#{avatar}.png"
  end
end
