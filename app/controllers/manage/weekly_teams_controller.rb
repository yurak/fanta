module Manage
  class WeeklyTeamsController < BaseController
    def index
      @weekly_teams = WeeklyTeam.includes(:team_module, :season, :tournament)
                                .order(created_at: :desc)
    end

    def new
      @source      = params[:source].presence_in(%w[round season avg auction]) || 'round'
      @mode        = params[:mode] == 'flop' ? :flop : :top
      @tournaments = @source == 'auction' ? auction_tournaments : scored_tournaments

      build_teams_for_source
    end

    def create
      weekly_team = WeeklyTeams::Saver.call(**create_params)

      if weekly_team
        redirect_to weekly_team_path(weekly_team), notice: t('manage.weekly_team.saved')
      else
        redirect_to new_manage_weekly_team_path, alert: t('manage.weekly_team.save_failed')
      end
    end

    private

    def build_teams_for_source
      case @source
      when 'round'   then build_round_teams
      when 'season'  then build_season_teams
      when 'avg'     then build_avg_teams
      when 'auction' then build_auction_teams
      end
    end

    def build_round_teams
      unfinished_ids = TournamentMatch.where(host_score: nil).select(:tournament_round_id)
      @rounds = TournamentRound.includes(:tournament)
                               .joins(:round_players)
                               .where('round_players.score > 0')
                               .where(tournament_rounds: { updated_at: 2.weeks.ago.. })
                               .where.not(id: unfinished_ids)
                               .distinct
                               .order('tournaments.id ASC, tournament_rounds.number ASC')
      @selected_ids = Array(params[:round_ids]).map(&:to_i).reject(&:zero?)
      @teams = WeeklyTeams::Builder.call(@selected_ids, mode: @mode) if @selected_ids.any?
    end

    def build_season_teams
      @rounds        = []
      @selected_ids  = []
      @tournament_id = params[:tournament_id].to_i
      return unless @tournament_id.positive?

      round_ids = TournamentRound.by_tournament(@tournament_id)
                                 .by_season(current_season.id)
                                 .pluck(:id)
      @teams = WeeklyTeams::Builder.call(round_ids, mode: @mode)
    end

    def build_avg_teams
      @rounds        = []
      @selected_ids  = []
      @tournament_id = params[:tournament_id].to_i
      return unless @tournament_id.positive?

      @teams = WeeklyTeams::SeasonAvgBuilder.call(@tournament_id, current_season.id)
    end

    def build_auction_teams
      @rounds        = []
      @selected_ids  = []
      @tournament_id = params[:tournament_id].to_i
      return unless @tournament_id.positive?

      @teams = WeeklyTeams::AuctionAvgBuilder.call(@tournament_id, current_season.id)
    end

    def auction_tournaments
      Tournament.joins(leagues: :auctions)
                .where(leagues: { season_id: current_season.id }, auctions: { number: 1 })
                .distinct
                .order(:id)
    end

    def scored_tournaments
      Tournament.joins(tournament_rounds: :round_players)
                .where(tournament_rounds: { season: current_season })
                .where('round_players.score > 0')
                .distinct
                .order(:id)
    end

    def current_season
      @current_season ||= Season.order(:start_year).last
    end

    def create_params
      {
        team_module_id: params[:team_module_id].to_i,
        round_ids: Array(params[:round_ids]).map(&:to_i).reject(&:zero?),
        mode: params[:mode].presence_in(%w[top flop]) || 'top',
        number: params[:number].to_i,
        players: Array(params[:players]),
        source: params[:source].presence_in(%w[round season avg auction]) || 'round',
        tournament_id: params[:tournament_id].presence&.to_i
      }
    end
  end
end
