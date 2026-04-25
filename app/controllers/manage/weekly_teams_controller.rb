module Manage
  class WeeklyTeamsController < BaseController
    def index
      @weekly_teams = WeeklyTeam.includes(:team_module, :season)
                                .order(created_at: :desc)
    end

    def new
      unfinished_ids = TournamentMatch.where(host_score: nil).select(:tournament_round_id)
      @rounds = TournamentRound.includes(:tournament)
                               .joins(:round_players)
                               .where('round_players.score > 0')
                               .where('tournament_rounds.updated_at >= ?', 2.weeks.ago)
                               .where.not(id: unfinished_ids)
                               .distinct
                               .order('tournaments.id ASC, tournament_rounds.number ASC')

      @selected_ids = Array(params[:round_ids]).map(&:to_i).reject(&:zero?)
      @mode = params[:mode] == 'flop' ? :flop : :top
      @teams = WeeklyTeams::Builder.call(@selected_ids, mode: @mode) if @selected_ids.any?
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

    def create_params
      {
        team_module_id: params[:team_module_id].to_i,
        round_ids: Array(params[:round_ids]).map(&:to_i).reject(&:zero?),
        mode: params[:mode].presence_in(%w[top flop]) || 'top',
        number: params[:number].to_i,
        players: Array(params[:players])
      }
    end
  end
end
