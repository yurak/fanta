class MatchesController < ApplicationController
  helper_method :match

  respond_to :html

  def show
    return redirect_to leagues_path unless match

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
    return @match if defined?(@match)

    @match = Match.includes(:host, :guest, tour: [:tournament_round, :league, { matches: %i[host guest] }])
                  .find_by(id: params[:id] || params[:match_id])
  end

  def preload_lineups(match)
    all_team_ids = match.tour.matches.flat_map { |m| [m.host_id, m.guest_id] }.uniq

    lineups = Lineup.includes(
      team_module: :slots,
      match_players: {
        round_player: { player: :club },
        main_subs: { out_rp: :player }
      }
    ).where(tour_id: match.tour_id, team_id: all_team_ids).index_by(&:team_id)

    ([match] + match.tour.matches.to_a).each do |m|
      m.define_singleton_method(:host_lineup) { lineups[host_id] }
      m.define_singleton_method(:guest_lineup) { lineups[guest_id] }
    end
  end
end
