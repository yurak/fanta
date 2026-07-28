module Manage
  class JoinsController < Manage::BaseController
    TABS = %w[pending initial approved].freeze

    def index
      @tab = TABS.include?(params[:tab]) ? params[:tab] : TABS.first
      @tournament_id = params[:tournament_id].presence&.to_i
      @tournament_counts = tournament_counts
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
      scope = apply_search(base_scope_for_tab)
      scope = scope.where(tournament_id: @tournament_id) if @tournament_id
      scope.page(params[:page]).per(PER_PAGE)
    end

    def base_scope_for_tab
      case @tab
      when 'pending'
        Join.pending.includes(:tournament, team: [:join, { league: :season }], user: :user_profile)
            .order('tournaments.id, joins.created_at ASC').references(:tournaments)
      when 'initial'
        Join.initial.includes(:tournament, team: [:join, { league: :season }], user: :user_profile).order(created_at: :asc)
      when 'approved'
        Join.approved.includes(:tournament, team: [:join, { league: :season }], user: :user_profile)
            .order('tournaments.name, leagues.name').references(:tournaments, :leagues)
      end
    end

    def tournament_counts
      counts = apply_search(Join.public_send(@tab)).group(:tournament_id).count
      Tournament.where(id: counts.keys).order(:id).index_with { |t| counts[t.id] }
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
