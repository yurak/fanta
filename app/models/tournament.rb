class Tournament < ApplicationRecord
  has_many :leagues, dependent: :destroy
  has_many :clubs, dependent: :destroy

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true

  scope :with_clubs, -> { includes(:clubs).where.not(clubs: { id: nil }) }

  def logo_path
    if File.exist?("app/assets/images/tournaments/#{code}.png")
      "tournaments/#{code}.png"
    else
      'tournaments/uefa.png'
    end
  end
end
