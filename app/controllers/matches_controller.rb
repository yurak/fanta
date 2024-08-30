class MatchesController < ApplicationController
  helper_method :match

  respond_to :html

  def show
    return redirect_to leagues_path unless match

    preload_lineups(match)
    preload_round_matches
    @prev_tour_match = first_round_match(match.tour.prev_round)
    @next_tour_match = first_round_match(match.tour.next_round)
  end

  def autobot
    match.autobot

    redirect_to match_path(match)
  end

  def autobot
    @match ||= Match.find(params[:match_id])

    @match.autobot

    redirect_to match_path(@match)
  end

  private

  def match
    return @match if defined?(@match)

    @match = Match.includes(
      { host: :league }, { guest: :league },
      tour: [:tournament_round, :league, { matches: [{ host: :league }, { guest: :league }] }]
    ).find_by(id: params[:id] || params[:match_id])
  end

  def preload_lineups(match)
    all_team_ids = match.tour.matches.flat_map { |m| [m.host_id, m.guest_id] }.uniq

    lineups = Lineup.includes(
      { team: :league },
      :tour,
      team_module: :slots,
      match_players: {
        round_player: [:club, :tournament_round, { player: [:national_team, { club: :tournament }] }],
        main_subs: { out_rp: :player }
      }
    ).where(tour_id: match.tour_id, team_id: all_team_ids).index_by(&:team_id)

    ([match] + match.tour.matches.to_a).each do |m|
      m.define_singleton_method(:host_lineup) { lineups[host_id] }
      m.define_singleton_method(:guest_lineup) { lineups[guest_id] }
    end
  end

  def preload_round_matches
    t_rounds = match.tour.matches.flat_map do |m|
      [m.host_lineup, m.guest_lineup].compact.flat_map do |lineup|
        lineup.match_players.filter_map { |mp| mp.round_player&.tournament_round }
      end
    end
    t_rounds << match.tour.tournament_round
    t_rounds = t_rounds.compact.uniq(&:id)
    return if t_rounds.empty?

    ActiveRecord::Associations::Preloader.new.preload(
      t_rounds,
      [{ tournament_matches: %i[host_club guest_club] }, :national_matches]
    )
  end

  def first_round_match(round)
    return unless round

    round.matches.includes({ host: :league }, { guest: :league }).first
  end
end
