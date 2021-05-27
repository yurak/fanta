class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :teams, dependent: :destroy

  EMAIL_LENGTH = (6..50).freeze
  EMAIL_FORMAT_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.a[a-z]+)*\.[a-z]+\z/i.freeze
  NAME_LENGTH = (2..15).freeze
  ROLES = %w[customer admin moderator].freeze

  enum role: ROLES

  validates :email, presence: true, format: { with: EMAIL_FORMAT_REGEX }, uniqueness: true
  validates :email, length: { in: EMAIL_LENGTH }
  validates :name, length: { in: NAME_LENGTH }, allow_blank: true
  validates :role, presence: true

  def can_moderate?
    admin? || moderator?
  end

  def team_by_league(league)
    teams.find_by(league_id: league.id)
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
end
