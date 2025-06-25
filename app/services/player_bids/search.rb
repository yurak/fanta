module PlayerBids
  class Search < ApplicationService
    attr_reader :auction_id, :name, :position, :round, :team_id

    def initialize(params)
      @auction_id = params[:auction_id]
      @name = params[:search]&.downcase
      @position = params[:position]
      @round = params[:round]
      @team_id = params[:team_id]
    end

    def call
      query = base_query
      if name.present?
        query = query.where('lower(players.name) LIKE :search OR lower(players.first_name) LIKE :search', search: "%#{name}%")
      end
      query = query.where('positions.human_name LIKE ?', position) if position.present?
      query = query.where(auction_rounds: { number: round }) if round.present?
      query = query.where(auction_bids: { team_id: team_id }) if team_id.present?

      @player_bid_groups = query.order('player_bids.price DESC')
                                .group_by { |bid| bid.auction_bid.auction_round.number }
                                .sort_by { |round_number, _| round_number }.reverse.to_h
    end

    private

    def base_query
      PlayerBid.joins('INNER JOIN auction_bids ON player_bids.auction_bid_id = auction_bids.id')
               .joins('INNER JOIN auction_rounds ON auction_bids.auction_round_id = auction_rounds.id')
               .joins('INNER JOIN auctions ON auction_rounds.auction_id = auctions.id')
               .joins('INNER JOIN players ON player_bids.player_id = players.id')
               .joins('INNER JOIN player_positions ON players.id = player_positions.player_id')
               .joins('INNER JOIN positions ON player_positions.position_id = positions.id').distinct
               .where('player_bids.status = 1')
               .where(auctions: { id: auction_id })
    end
  end
end
