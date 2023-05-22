module AuctionBids
  class Manager < ApplicationService
    INITIAL_STATUS = 'initial'.freeze
    ONGOING_STATUS = 'ongoing'.freeze
    SUBMITTED_STATUS = 'submitted'.freeze
    COMPLETED_STATUS = 'completed'.freeze
    PROCESSED_STATUS = 'processed'.freeze

    attr_reader :auction_bid, :params, :status, :team

    def initialize(auction_bid, team, params)
      @auction_bid = auction_bid
      @status = auction_bid.status
      @team = team
      @params = params
    end

    def call
      submit

      complete

      # TODO: add actions for other statuses
    end

    private

    def submit
      return false if [INITIAL_STATUS, ONGOING_STATUS].exclude? status
      return false unless valid_bid?

      auction_bid.update(params)
      auction_bid.submitted!
    end

    def complete
      return false unless status == SUBMITTED_STATUS

      # TODO:
      # auction_bid.update(params)
    end

    def valid_bid?
      return false if duplicate_players&.any?
      return false if players_ids.count < team.vacancies
      return false if total_price > team.budget
      return false if gk_count < Team::MIN_GK
      return false if contains_dumped?

      true
    end

    def total_price
      params[:player_bids_attributes].values.each_with_object([]) { |el, prices| prices << el[:price] }.sum(&:to_i)
    end

    def players_ids
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

    def auction_round
      @auction_round ||= auction_bid.auction_round
    end
  end
end
