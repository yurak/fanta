class League < ApplicationRecord
  COLORS = %w[#007bff #fd7e14 #28a745 #6c757d #ffc107 #dc3545 #6f42c1 #20c997 #e83e8c #17a2b8 #6610f2].freeze

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
  scope :with_division, -> { where.not(division: { id: nil }) }
  scope :viewable, -> { active.or(archived) }
  scope :serial, lambda {
    includes(:division, :results, :season, :teams, :tournament, :tours)
      .order('season_id DESC, tournament_id ASC')
      .order(Arel.sql('CASE WHEN division_id IS NULL THEN 1 ELSE 0 END, division_id ASC'))
  }

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

  def chart_data
    return {} if tours.closed.blank?

    positions = results.each_with_object([]).with_index do |(result, array), index|
      history_arr = JSON.parse(result.history).drop(1)
      team_pos_arr = history_arr.each_with_object([]) { |round, pos_arr| pos_arr << round&.dig('pos') }
      array << { label: result.team.human_name, data: team_pos_arr, borderColor: COLORS[index], backgroundColor: COLORS[index] }
    end

    { labels: (1..tours.closed.last.number).to_a, datasets: positions }.to_json
  end
end
