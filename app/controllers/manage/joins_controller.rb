module Manage
  class JoinsController < Manage::BaseController
    def index
      @joins = Join.pending.includes(:user, :tournament, team: :join).order(created_at: :asc)
    end

    def approve
      league = League.find(params[:league_id])

      join.update!(status: :approved)
      join.team.update!(league: league)

      bid = join.team.auction_bids.find_by(auction_round: nil)
      if bid
        auction_round = league.auctions.active.first&.auction_rounds&.last
        bid.update!(auction_round: auction_round) if auction_round
      end

      redirect_to manage_joins_path, notice: t('admin.joins.approved')
    end

    def reject
      join.update!(status: :rejected)
      redirect_to manage_joins_path, notice: t('admin.joins.rejected')
    end

    private

    def join
      @join ||= Join.find(params[:id])
    end
  end
end
