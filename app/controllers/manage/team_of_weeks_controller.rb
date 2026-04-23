module Manage
  class TeamOfWeeksController < BaseController
    def index
      @rounds = TournamentRound.includes(:tournament)
                               .joins(:round_players)
                               .where('round_players.score > 0')
                               .where('tournament_rounds.updated_at >= ?', 2.weeks.ago)
                               .distinct
                               .order('tournaments.id ASC, tournament_rounds.number ASC')

      @selected_ids = Array(params[:round_ids]).map(&:to_i).reject(&:zero?)
      @mode = params[:mode] == 'flop' ? :flop : :top
      @teams = TeamOfWeek::Builder.call(@selected_ids, mode: @mode) if @selected_ids.any?
    end
  end
end
