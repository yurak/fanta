module Api
  class AuctionSalesController < Api::ApplicationController
    include Api::AuctionDocument

    skip_before_action :authenticate_user!, only: :index

    def index
      return not_found unless auction

      render json: { data: sales_document }
    end

    private

    def sales
      @sales ||= Auctions::Sales.call(auction)
    end

    def sales_document
      {
        auction: auction_meta,
        teams: teams_current_first(sales[:teams]).map { |group| team_group(group) },
        top_earners: sales[:top_earners].map { |entry| ranking(entry) },
        top_droppers: sales[:top_droppers].map { |entry| ranking(entry) },
        top_sale: sales[:top_sale].map { |transfer| transfer_row(transfer) }
      }
    end

    def team_group(group)
      {
        team: team_hash(group.team),
        net_income: group.net_income,
        dropped: group.dropped.map { |transfer| transfer_row(transfer) },
        left: group.left.map { |transfer| transfer_row(transfer) }
      }
    end
  end
end
