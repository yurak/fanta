class MatchesController < ApplicationController
  helper_method :match

  respond_to :html

  def show
    redirect_to leagues_path unless match

    preload_lineups(match)
    @prev_tour_match = match.tour.prev_round&.matches&.first
    @next_tour_match = match.tour.next_round&.matches&.first
  end

  def autobot
    match.autobot

    redirect_to match_path(match)
  end

  private

  def match
    @match ||= Match.includes(:host, :guest, tour: %i[tournament_round league])
                    .find_by(id: params[:id] || params[:match_id])
  end

  def preload_lineups(match)
    lineups = Lineup.includes(team_module: :slots, match_players: { round_player: { player: :club } })
                    .where(tour_id: match.tour_id, team_id: [match.host_id, match.guest_id]).index_by(&:team_id)

    match.define_singleton_method(:host_lineup) { lineups[host_id] }
    match.define_singleton_method(:guest_lineup) { lineups[guest_id] }
  end
end
