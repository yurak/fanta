module Manage
  class JoinsController < Manage::BaseController
    def index
      @pending_joins = Join.pending.includes(:user, :tournament, team: :join).order(created_at: :asc)
      @initial_joins = Join.initial.includes(:user, :tournament, team: :join).order(created_at: :asc)
      @approved_joins = Join.approved
                            .includes(:user, :tournament, team: %i[join league])
                            .order('tournaments.name, leagues.name')
                            .references(:tournaments, :leagues)
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

      redirect_to manage_joins_path, notice: t('manage.joins.approved')
    end

    def reject
      join.update!(status: :rejected)
      redirect_to manage_joins_path, notice: t('manage.joins.rejected')
    end

    private

    def join
      @join ||= Join.find(params[:id])
    end
  end
end
