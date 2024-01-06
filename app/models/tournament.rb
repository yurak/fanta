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

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true

  scope :with_clubs, -> { includes(:clubs, :leagues).where.not(clubs: { id: nil }).where.not(clubs: { status: 'archived' }) }
  scope :with_ec_clubs, -> { includes(:ec_clubs, :leagues).where.not(ec_clubs: { id: nil }).where.not(ec_clubs: { status: 'archived' }) }
  scope :active, -> { with_clubs.order(:id) + with_ec_clubs }

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
