class Tournament < ApplicationRecord
  has_many :article_tags, dependent: :destroy
  has_many :clubs, dependent: :destroy
  has_many :leagues, dependent: :destroy
  has_many :links, dependent: :destroy
  has_many :national_teams, dependent: :destroy
  has_many :tournament_rounds, dependent: :destroy

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true

  scope :with_clubs, -> { includes(:clubs).where.not(clubs: { id: nil, status: 'archived' }) }

  def logo_path
    if File.exist?("app/assets/images/tournaments/#{code}.png")
      "tournaments/#{code}.png"
    else
      'tournaments/uefa.png'
    end
  end
end
