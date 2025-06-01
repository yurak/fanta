class AuctionRound < ApplicationRecord
  belongs_to :auction

  has_many :auction_bids, dependent: :destroy
  has_many :player_bids, through: :auction_bids

  validates :number, presence: true

  delegate :league, to: :auction

  FULL_SIZE_ROUND = 4
  BUDGET_LIMIT = [0, 170, 200, 230, 260].freeze
  GK_MIN_LIMIT = [0, 0, 1, 2, 3].freeze
  GK_BASE_MIN_LIMIT = 3

  enum status: { active: 0, processing: 1, closed: 2 }

  def bid_exist?(team)
    return false unless team

    auction_bids.find_by(team_id: team.id).present?
  end

  def members
    league.teams.select(&:vacancies?)
  end

  def first?
    number == 1
  end

  def slots_number
    number >= FULL_SIZE_ROUND ? Team::MAX_PLAYERS : number * league.auction_step
  end

  def slots_number_by(team)
    return 0 unless team

    if auction.primary?
      (slots_number - team.players.count)
    else
      team.vacancies
    end
  end

  def budget_limit
    auction.primary? && number < FULL_SIZE_ROUND ? BUDGET_LIMIT[number] : Team::DEFAULT_BUDGET
  end

  def gk_min_limit
    auction.primary? && number < FULL_SIZE_ROUND ? GK_MIN_LIMIT[number] : Team::MIN_GK
  end
end
