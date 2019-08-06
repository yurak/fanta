class Team < ApplicationRecord
  has_many :players, dependent: :destroy

  validates :name, uniqueness: true

  has_many :lineups, dependent: :destroy

  def logo_path
    if File.exist?("app/assets/images/teams/#{name}.png")
      "teams/#{name}.png"
    else
      'fanta.png'
    end
  end
end
