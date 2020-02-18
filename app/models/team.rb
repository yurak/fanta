class Team < ApplicationRecord
  belongs_to :league
  belongs_to :user, optional: true
  # TODO: change to has_and_belongs_to_many :players
  has_many :players, dependent: :destroy
  has_many :lineups, -> { order('tour_id desc') }, dependent: :destroy
  has_many :host_matches, foreign_key: 'host_id', class_name: 'Match'
  has_many :guest_matches, foreign_key: 'guest_id', class_name: 'Match'
  has_one :result, dependent: :destroy

  validates :name, uniqueness: true

  def matches
    @matches ||= Match.where('host_id = ? OR guest_id = ?', id, id)
  end

  def logo_path
    if File.exist?("app/assets/images/teams/#{name}.png")
      "teams/#{name}.png"
    else
      'fanta.png'
    end
  end
end
