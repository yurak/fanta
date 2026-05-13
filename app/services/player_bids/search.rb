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

      query.order('player_bids.price DESC')
           .group_by { |bid| bid.auction_bid.auction_round.number }
           .sort_by { |round_number, _| -round_number }
           .to_h
    end

    private

    def base_query
      PlayerBid.joins(auction_bid: { auction_round: :auction }, player: { player_positions: :position })
               .includes(
                 player: %i[positions club],
                 auction_bid: %i[auction_round team]
               )
               .distinct
               .success
               .where(auctions: { id: auction_id })
    end
  end
end
