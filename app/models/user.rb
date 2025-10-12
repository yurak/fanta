class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :confirmable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :join_requests, dependent: :destroy
  has_many :teams, dependent: :destroy
  has_many :leagues, through: :teams
  has_many :results, through: :teams
  has_many :lineups, through: :teams
  has_many :transfers, through: :teams
  has_many :player_requests, dependent: :destroy
  has_one :user_profile, dependent: :destroy

  accepts_nested_attributes_for :user_profile

  EMAIL_LENGTH = (6..50).freeze
  EMAIL_FORMAT_REGEX = /\A[\w+\-.]+@[a-z\d-]+(\.a[a-z]+)*\.[a-z]+\z/i.freeze
  NAME_LENGTH = (2..20).freeze
  ROLES = %w[customer admin moderator].freeze

  enum role: ROLES
  enum status: { initial: 0, named: 1, with_avatar: 2, with_team: 3, configured: 4 }
  enum locale: { en: 0, ua: 1 }

  validates :email, presence: true, format: { with: EMAIL_FORMAT_REGEX }, uniqueness: true
  validates :email, length: { in: EMAIL_LENGTH }
  validates :name, length: { in: NAME_LENGTH }, allow_blank: false, if: :name_changed?
  validates :role, presence: true

  before_create :generate_unsubscribe_token

  def generate_unsubscribe_token
    self.unsubscribe_token ||= SecureRandom.hex(16)
  end

  def can_moderate?
    admin? || moderator?
  end

  def team_by_league(league)
    teams.find_by(league_id: league&.id)
  end

  def lineup_by_tour(tour)
    team_by_league(tour.league)&.lineups&.find_by(tour: tour)
  end

  def avatar_path
    avatar_url || "avatars/avatar_#{avatar}.png"
  end

  def initial_avatar?
    avatar == '1'
  end

  def titles
    results.finished.title
  end

  def win_rate
    return 0 unless results.mantra.any?

    matches = results.mantra.sum { |r| r.wins + r.draws + r.loses }
    return 0 if matches.zero?

    (results.mantra.sum(:wins).to_f * 100 / matches).round(2)
  end

  def finished_mantra_lineups
    @finished_mantra_lineups ||= lineups.finished.mantra
  end

  def finished_fanta_lineups
    @finished_fanta_lineups ||= lineups.finished.fanta
  end

  def average_mantra_ts
    return 0 unless finished_mantra_lineups.any?

    (finished_mantra_lineups.sum(:final_score) / finished_mantra_lineups.count).round(2)
  end

  def average_fanta_ts
    return 0 unless finished_fanta_lineups.any?

    (finished_fanta_lineups.sum(:final_score) / finished_fanta_lineups.count).round(2)
  end

  def mantra_best_ts
    return 0 unless finished_mantra_lineups.any?

    finished_mantra_lineups.map(&:final_score).max
  end

  def fanta_best_ts
    return 0 unless finished_fanta_lineups.any?

    finished_fanta_lineups.map(&:final_score).max
  end

  def average_position
    valid_results = results.finished.mantra.with_position
    return 0 unless valid_results.any?

    (valid_results.sum(:position).to_f / valid_results.count).round(2)
  end

  def promotions
    results.finished.select(&:promoted?)
  end

  def relegations
    results.finished.select(&:relegated?)
  end

  def fanta_top
    results.fanta_top(10)
  end

  def fanta_top_ts
    results.fanta_top_ts(10)
  end

  protected

  def password_required?
    confirmed? ? super : false
  end
end
