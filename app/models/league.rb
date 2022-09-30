class League < ApplicationRecord
  belongs_to :division, optional: true
  belongs_to :season
  belongs_to :tournament

  has_many :auctions, dependent: :destroy
  has_many :teams, dependent: :destroy
  has_many :players, through: :teams
  has_many :transfers, dependent: :destroy
  has_many :tours, dependent: :destroy
  has_many :results, dependent: :destroy

  enum auction_type: { blind_bids: 0, live: 1 }
  enum cloning_status: { unclonable: 0, cloneable: 1 }
  enum status: { initial: 0, active: 1, archived: 2 }
  enum transfer_status: { closed: 0, open: 1 }

  validates :name, presence: true, uniqueness: true

  default_scope { includes(%i[division season tournament]) }

  scope :by_tournament, ->(tournament_id) { where(tournament: tournament_id) }

  def active_tour
    tours&.active&.first || tours.inactive&.first
  end

  def active_tour_or_last
    active_tour || tours.last
  end

  def leader
    result = results.find { |r| r.position == 1 }
    result&.team
  end

  def mantra?
    tours.first&.mantra?
  end
end
