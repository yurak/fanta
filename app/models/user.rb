class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :confirmable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :join_requests, dependent: :destroy
  has_many :teams, dependent: :destroy
  has_many :leagues, through: :teams
  has_many :player_requests, dependent: :destroy
  has_one :user_profile, dependent: :destroy

  accepts_nested_attributes_for :user_profile

  EMAIL_LENGTH = (6..50).freeze
  EMAIL_FORMAT_REGEX = /\A[\w+\-.]+@[a-z\d-]+(\.a[a-z]+)*\.[a-z]+\z/i.freeze
  NAME_LENGTH = (2..20).freeze
  ROLES = %w[customer admin moderator].freeze

  enum role: ROLES
  enum status: { initial: 0, named: 1, with_avatar: 2, with_team: 3, configured: 4 }

  validates :email, presence: true, format: { with: EMAIL_FORMAT_REGEX }, uniqueness: true
  validates :email, length: { in: EMAIL_LENGTH }
  validates :name, length: { in: NAME_LENGTH }, allow_blank: false, if: :name_changed?
  validates :role, presence: true

  def can_moderate?
    admin? || moderator?
  end

  def team_by_league(league)
    teams.find_by(league_id: league&.id)
  end

  def lineup_by_tour(tour)
    team_by_league(tour.league)&.lineups&.find_by(tour: tour)
  end

  def active_team
    return unless teams

    @active_team ||= teams.find_by(id: active_team_id) || teams.first
  end

  def active_league
    active_team&.league
  end

  def next_tour
    active_league&.active_tour
  end

  def avatar_path
    "avatars/avatar_#{avatar}.png"
  end

  def initial_avatar?
    avatar == '1'
  end

  protected

  def password_required?
    confirmed? ? super : false
  end
end
