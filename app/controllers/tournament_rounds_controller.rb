class TournamentRoundsController < ApplicationController
  respond_to :html, :json

  helper_method :tournament_round

  def show
    redirect_to leagues_path unless can? :show, TournamentRound
  end

  def edit
    redirect_to leagues_path unless can? :edit, TournamentRound

    @round_players = if tournament_round.tournament.national?
                       tournament_round.round_players.ordered_by_national
                     elsif params[:club_id]
                       tournament_round.round_players.by_club(params[:club_id]).sort_by { |x| [x.club.id, x.name] }
                     else
                       tournament_round.round_players.ordered_by_club
                     end
  end

  def update
    if can? :update, TournamentRound
      round_players.each_pair do |id, params|
        rp = RoundPlayer.find(id.to_i)
        rp.update(params.to_hash)
      end
    end

    redirect_to tournament_round_path(tournament_round)
  end

  def tours_update
    if can? :update, TournamentRound
      tournament_round.tours.each do |tour|
        Tours::Manager.new(tour, params[:status]).call
      end

      path = tournament_round_path(tournament_round)
    else
      path = leagues_path
    end

    redirect_to path
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

  def tournament_round
    @tournament_round ||= TournamentRound.find(params[:id])
  end
end
