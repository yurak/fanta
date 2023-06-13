module AuctionBids
  class Manager < ApplicationService
    INITIAL_STATUS = 'initial'.freeze
    ONGOING_STATUS = 'ongoing'.freeze
    SUBMITTED_STATUS = 'submitted'.freeze
    COMPLETED_STATUS = 'completed'.freeze
    PROCESSED_STATUS = 'processed'.freeze

    attr_reader :auction_bid, :auction_status, :params

    def initialize(auction_bid, params)
      @auction_bid = auction_bid
      @auction_status = auction_bid&.status
      @params = params
    end

    def call
      return false unless auction_bid && team
      return false if auction_status == PROCESSED_STATUS

      submit if new_status == SUBMITTED_STATUS

      complete if new_status == COMPLETED_STATUS

      ongoing if new_status == ONGOING_STATUS
    end

    private

    def submit
      return false if [INITIAL_STATUS, ONGOING_STATUS].exclude? auction_status
      return false unless valid_bid?

      auction_bid.update(params)
    end

    def complete
      return false unless auction_status == SUBMITTED_STATUS
      return false unless valid_bid?

      auction_bid.update(params)
    end

    def ongoing
      return false unless auction_status == COMPLETED_STATUS

      auction_bid.update(params.slice(:status))
    end

    def valid_bid?
      return false if players_ids.count < team.vacancies
      return false if duplicate_players&.any?
      return false if total_price > team.budget
      return false if gk_count < Team::MIN_GK
      return false if contains_dumped?

      true
    end

    def new_status
      params[:status]
    end

    def total_price
      params[:player_bids_attributes].values.each_with_object([]) { |el, prices| prices << el[:price] }.sum(&:to_i)
    end

    def players_ids
      return [] unless params[:player_bids_attributes]

      params[:player_bids_attributes].values.each_with_object([]) { |el, p_ids| p_ids << el[:player_id].to_i }.compact_blank
    end

    def duplicate_players
      players_ids&.find_all { |id| players_ids.rindex(id) != players_ids.index(id) }
    end

    def gk_count
      @gk_count ||= Player.by_position('Por').where(id: players_ids + team.players.map(&:id)).count
    end

    def contains_dumped?
      players_ids.intersection(dumped_player_ids).any?
    end

    def dumped_player_ids
      team.transfers.outgoing.by_auction(auction_round.auction).pluck(:player_id)
    end

    def team
      @team ||= auction_bid.team
    end

    def auction_round
      @auction_round ||= auction_bid.auction_round
    end
  end
end
