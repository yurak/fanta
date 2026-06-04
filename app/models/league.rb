class League < ApplicationRecord
  COLORS = %w[#007bff #fd7e14 #28a745 #6c757d #ffc107 #dc3545 #6f42c1 #20c997 #e83e8c #17a2b8 #6610f2].freeze
  FANTA = 'fanta'.freeze
  MANTRA = 'mantra'.freeze

  belongs_to :division, optional: true
  belongs_to :season
  belongs_to :tournament

  has_many :auctions, -> { order(:id) }, dependent: :destroy, inverse_of: :league
  has_many :teams, -> { order(:id) }, dependent: :destroy, inverse_of: :league
  has_many :players, through: :teams
  has_many :transfers, dependent: :destroy
  has_many :tours, -> { order(:number) }, dependent: :destroy, inverse_of: :league
  has_many :results, dependent: :destroy

  delegate :fanta?, :mantra?, to: :tournament

  enum auction_type: { blind_bids: 0, live: 1 }
  enum cloning_status: { unclonable: 0, cloneable: 1 }
  enum status: { initial: 0, active: 1, archived: 2 }
  enum transfer_status: { closed: 0, open: 1 }

  validates :name, presence: true, uniqueness: { scope: :season_id }
  validates :join_code, uniqueness: true, allow_blank: true,
                        format: { with: /\A[A-Z0-9]+\z/ }
  validate :only_one_default_per_tournament, if: -> { default_for_join? }

  before_validation :normalize_join_code
  before_validation :reset_auction_number_for_fanta, if: -> { tournament&.fanta? }
  before_save :generate_join_code, if: -> { open_for_join? && join_code.blank? }

  scope :by_tournament, ->(tournament_id) { where(tournament_id: tournament_id) if tournament_id.present? }
  scope :open_for_join, -> { where(open_for_join: true) }
  scope :by_season, ->(season_id) { where(season_id: season_id) if season_id.present? }
  scope :with_division, -> { where.not(division: { id: nil }) }
  scope :viewable, -> { active.or(archived) }
  scope :without_demo_from_old_seasons, -> { where('leagues.demo = ? OR leagues.season_id = ?', false, Season.last.id) }
  scope :serial, lambda {
    left_joins(:division)
      .includes(:division, :results, :season, :teams, :tournament, :tours)
      .order(
        Arel.sql(<<~SQL.squish)
          season_id DESC,
          tournament_id ASC,
          CASE WHEN division_id IS NULL THEN 1 ELSE 0 END,
          divisions.level ASC,
          divisions.number ASC,
          leagues.id ASC
        SQL
      )
  }

  def all_tours_closed?
    tours.any? && tours.where.not(status: Tour.statuses[:closed]).none?
  end

  def division_with_name
    return name unless division

    "#{name} (#{division.name})"
  end

  def active_tour
    @active_tour ||= tours
                     .reorder(Arel.sql("CASE
                         WHEN status IN (#{Tour.statuses[:set_lineup]}, #{Tour.statuses[:locked]}) THEN 0
                         WHEN status = #{Tour.statuses[:inactive]} THEN 1
                         ELSE 2
                       END"))
                     .first
  end

  def active_tour_or_last
    @active_tour_or_last ||= tours
                             .reorder(Arel.sql(<<~SQL.squish))
                               CASE
                                 WHEN status IN (#{Tour.statuses[:set_lineup]}, #{Tour.statuses[:locked]}) THEN 0
                                 WHEN status = #{Tour.statuses[:inactive]} THEN 1
                                 WHEN status = #{Tour.statuses[:closed]} THEN 2
                                 ELSE 3
                               END,
                               CASE
                                 WHEN status = #{Tour.statuses[:closed]} THEN -id
                                 ELSE id
                               END
                             SQL
                             .first
  end

  def leader
    result = results.find { |r| r.live_position == 1 }
    result&.team
  end

  def type
    fanta? ? FANTA : MANTRA
  end

  def chart_data
    return {} if tours.closed.blank?

    positions = results.each_with_object([]).with_index do |(result, array), index|
      history_arr = JSON.parse(result.history).drop(1)
      team_pos_arr = history_arr.each_with_object([]) { |round, pos_arr| pos_arr << round&.fetch('pos') }
      array << { label: result.team.human_name, data: team_pos_arr, borderColor: COLORS[index], backgroundColor: COLORS[index] }
    end

    { labels: (1..tours.closed.last.number).to_a, datasets: positions }.to_json
  end

  private

  def generate_join_code
    loop do
      self.join_code = Array.new(6) { ('A'..'Z').to_a.sample }.join
      break unless League.exists?(join_code: join_code)
    end
  end

  def reset_auction_number_for_fanta
    self.auction_number = 0
  end

  def only_one_default_per_tournament
    exists = League.where(tournament_id: tournament_id, open_for_join: true, default_for_join: true)
                   .where.not(id: id)
                   .exists?
    errors.add(:default_for_join, :taken) if exists
  end

  def normalize_join_code
    self.join_code = join_code.presence&.upcase
  end
end
