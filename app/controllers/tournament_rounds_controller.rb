class TournamentRoundsController < ApplicationController
  respond_to :html, :json

  helper_method :tournament_round

  def show
    redirect_to leagues_path unless can? :show, TournamentRound

    @finished = tournament_round.finished?
  end

  def edit
    redirect_to leagues_path unless can? :edit, TournamentRound

    @round_players = if tournament_round.tournament.national?
                       edit_round_players.ordered_by_national
                     elsif params[:club_id]
                       edit_round_players.by_club(params[:club_id]).sort_by { |x| [x.club.id, x.name] }
                     else
                       edit_round_players.ordered_by_club
                     end
  end

  def update
    if can? :update, TournamentRound
      rps = RoundPlayer.where(id: round_players.keys).index_by { |rp| rp.id.to_s }
      round_players.each_pair do |id, params|
        rp = rps[id]
        next unless rp

        hash = params.to_hash
        hash['in_squad'] = true if hash['score'].to_f.positive? || hash['played_minutes'].to_i.positive?
        rp.update(hash)
      end
    end

    redirect_to tournament_round_path(tournament_round)
  end

  def tours_update
    if can? :update, TournamentRound
      tournament_round.tours.each do |tour|
        Tours::Manager.call(tour, params[:status])
      end

      path = tournament_round_path(tournament_round)
    else
      path = leagues_path
    end

    redirect_to path
  end

  def stats
    redirect_to leagues_path unless can? :show, TournamentRound
  end

  def missed_players
    redirect_to leagues_path unless can? :show, TournamentRound
  end

  def auto_close
    TournamentRounds::AutoCloser.call(params[:id])

    redirect_to tournament_round_path(tournament_round)
  end

  def auto_subs_preview; end

  def auto_subs
    Substitutes::AutoBot.for_round(tournament_round, preview: false) if can? :auto_subs, TournamentRound

    redirect_to tournament_round_auto_subs_preview_path(tournament_round)
  end

  def generate_preview
    Substitutes::AutoBot.for_round(tournament_round) if can? :generate_preview, TournamentRound

    redirect_to tournament_round_auto_subs_preview_path(tournament_round)
  end

  private

  def round_players
    update_params['round_players']
  end

  def update_params
    params.permit(round_players: %i[id score goals missed_goals scored_penalty failed_penalty cleansheet saves
                                    assists yellow_card red_card own_goals caught_penalty missed_penalty conceded_penalty
                                    played_minutes penalties_won manual_lock])
  end

  def edit_round_players
    tournament_round.round_players.includes(:club, player: %i[club national_team positions])
  end

  def tournament_round
    @tournament_round ||= TournamentRound.includes(
      tours: { league: :division },
      tournament_matches: %i[host_club guest_club]
    ).find(params[:id] || params[:tournament_round_id])
  end
end
