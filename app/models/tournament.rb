class Tournament < ApplicationRecord
  has_many :article_tags, dependent: :destroy
  has_many :clubs, dependent: :destroy
  has_many :leagues, dependent: :destroy
  has_many :links, dependent: :destroy
  has_many :national_teams, dependent: :destroy
  has_many :player_season_stats, dependent: :destroy
  has_many :tournament_rounds, dependent: :destroy
  has_many :ec_clubs, foreign_key: 'ec_tournament_id', class_name: 'Club',
                      dependent: :destroy, inverse_of: :ec_tournament

  enum source: { fotmob: 0, sofascore: 1 }

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true

  scope :with_clubs, -> { includes(:clubs, :leagues).where.not(clubs: { id: nil }).where.not(clubs: { status: 'archived' }) }
  scope :with_ec_clubs, -> { includes(:ec_clubs, :leagues).where.not(ec_clubs: { id: nil }).where.not(ec_clubs: { status: 'archived' }) }
  scope :with_national_teams, -> { where.not(national_teams: { id: nil }).where.not(national_teams: { status: 'archived' }) }
  scope :with_national, -> { includes(:national_teams, :leagues).with_national_teams }
  scope :active, -> { with_clubs.order(:id) + with_ec_clubs + with_national }
  scope :open_join, -> { where(open_join: true) }

  def logo_path
    if File.exist?("app/assets/images/tournaments/#{code}.png")
      "tournaments/#{code}.png"
    else
      'tournaments/uefa.png'
    end
  end

  def national?
    national_teams.any?
  end

  def fanta?
    national? || eurocup?
  end
end
