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

      redirect_to manage_joins_path(return_params), notice: t('manage.joins.approved')
    end

    def reject
      join.update!(status: :rejected)
      redirect_to manage_joins_path(return_params), notice: t('manage.joins.rejected')
    end

    private

    def return_params
      { tab: 'pending', tournament_id: params[:tournament_id].presence, page: params[:page].presence,
        user_id: params[:user_id].presence, team_name: params[:team_name].presence }.compact
    end

    def joins_for_tab
      case @tab
      when 'pending'  then pending_joins
      when 'initial'  then initial_joins
      when 'approved' then approved_joins
      end
    end

    def initial_joins
      apply_search(Join.initial.includes(:tournament, team: :join, user: :user_profile))
        .order(created_at: :asc)
        .page(params[:page]).per(PER_PAGE)
    end

    def pending_joins
      @tournament_id = params[:tournament_id].presence&.to_i
      @pending_counts = pending_counts

      scope = apply_search(Join.pending.includes(:tournament, team: :join, user: :user_profile))
              .order('tournaments.id, joins.created_at ASC')
              .references(:tournaments)
      scope = scope.where(tournament_id: @tournament_id) if @tournament_id
      scope.page(params[:page]).per(PER_PAGE)
    end

    # { tournament => pending_count } for the tournament subtabs, ordered by tournament id.
    def pending_counts
      counts = apply_search(Join.pending).group(:tournament_id).count
      Tournament.where(id: counts.keys).order(:id).index_with { |t| counts[t.id] }
    end

    def approved_joins
      apply_search(Join.approved.includes(:tournament, team: %i[join league], user: :user_profile))
        .order('tournaments.name, leagues.name')
        .references(:tournaments, :leagues)
        .page(params[:page]).per(PER_PAGE)
    end

    def apply_search(scope)
      scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
      return scope if params[:team_name].blank?

      scope.where(team: Team.where('human_name ILIKE ?', "%#{params[:team_name]}%"))
    end

    def join
      @join ||= Join.find(params.expect(:id))
    end
  end
end
