module Api
  class AuctionPurchasesController < Api::ApplicationController
    include Api::AuctionDocument

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
        stages: purchases[:stages],
        current_team_id: current_team_id,
        teams: teams_current_first(purchases[:teams]).map { |group| team_group(group) },
        top_spenders: purchases[:top_spenders].map { |entry| ranking(entry) },
        top_buy: purchases[:top_buy].map { |transfer| purchase_row(transfer) }
      }
    end

    def team_group(group)
      {
        team: team_hash(group.team),
        total_spent: group.total_spent,
        bought: group.bought.map { |transfer| purchase_row(transfer) }
      }
    end

    def purchase_row(transfer)
      transfer_row(transfer).merge(stage: purchases[:stage_by][transfer.id])
    end
  end
end
