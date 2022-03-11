class AuctionRound < ApplicationRecord
  belongs_to :auction

  has_many :auction_bids, dependent: :destroy
  has_many :player_bids, through: :auction_bids

  delegate :league, to: :auction

  enum status: { active: 0, processing: 1, closed: 2 }

  def bid_exist?(team)
    return false unless team

    auction_bids.find_by(team_id: team.id).present?
  end

  def members
    league.teams.select(&:vacancies?)
  end
end
