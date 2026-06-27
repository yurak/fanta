module Manage
  class JoinsController < Manage::BaseController
    TABS = %w[pending initial approved].freeze

    def index
      @tab = TABS.include?(params[:tab]) ? params[:tab] : TABS.first
      @joins = joins_for_tab
    end

    def approve
      league = League.find(params.expect(:league_id))

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

    def joins_for_tab
      case @tab
      when 'pending'  then pending_joins
      when 'initial'  then Join.initial.includes(:tournament, team: :join, user: :user_profile).order(created_at: :asc)
      when 'approved' then approved_joins
      end
    end

    def pending_joins
      pending = Join.pending.includes(:tournament, team: :join, user: :user_profile)
                    .order('tournaments.id, joins.created_at ASC')
                    .references(:tournaments)
      @pending_by_tournament = pending.group_by(&:tournament)
      @tournament_id = params[:tournament_id].presence&.to_i
      @tournament_id ? pending.select { |j| j.tournament_id == @tournament_id } : pending
    end

    def approved_joins
      Join.approved
          .includes(:tournament, team: %i[join league], user: :user_profile)
          .order('tournaments.name, leagues.name')
          .references(:tournaments, :leagues)
    end

    def join
      @join ||= Join.find(params.expect(:id))
    end
  end
end
