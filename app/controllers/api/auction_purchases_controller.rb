module Api
  class AuctionPurchasesController < Api::ApplicationController
    include Api::AuctionDocument

    skip_before_action :authenticate_user!, only: :index

    def index
      return not_found unless auction

      render json: { data: purchases_document }
    end

    private

    def purchases
      @purchases ||= Auctions::Purchases.call(auction)
    end

    def purchases_document
      {
        auction: auction_meta,
        teams: teams_current_first(purchases[:teams]).map { |group| team_group(group) },
        top_spenders: purchases[:top_spenders].map { |entry| ranking(entry) },
        top_buy: purchases[:top_buy].map { |transfer| transfer_row(transfer) }
      }
    end

    def team_group(group)
      {
        team: team_hash(group.team),
        total_spent: group.total_spent,
        bought: group.bought.map { |transfer| transfer_row(transfer) }
      }
    end
  end
end
