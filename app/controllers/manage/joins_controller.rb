module Manage
  class JoinsController < Manage::BaseController
    TABS = %w[pending initial approved].freeze

    def index
      @tab = TABS.include?(params[:tab]) ? params[:tab] : TABS.first
      @joins = case @tab
               when 'pending'
                 Join.pending.includes(:user, :tournament, team: :join)
                     .order('tournaments.id, joins.created_at ASC')
                     .references(:tournaments)
               when 'initial'
                 Join.initial.includes(:user, :tournament, team: :join).order(created_at: :asc)
               when 'approved'
                 Join.approved
                     .includes(:user, :tournament, team: %i[join league])
                     .order('tournaments.name, leagues.name')
                     .references(:tournaments, :leagues)
               end
    end

    def approve
      league = League.find(params[:league_id])

      join.update!(status: :approved)
      join.team.update!(league: league)

      bid = join.auction_bid
      if bid.auction_round_id.nil?
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
