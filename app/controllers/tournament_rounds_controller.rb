class TournamentRoundsController < ApplicationController
  respond_to :html, :json

  helper_method :tournament_round

  def edit
    redirect_to leagues_path unless can? :edit, TournamentRound

    @round_players = if tournament_round.tournament.national?
                       tournament_round.round_players.ordered_by_national
                     elsif params[:club_id]
                       tournament_round.round_players.by_club(params[:club_id]).order('name')
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

    redirect_to leagues_path
  end

  private

  def round_players
    update_params['round_players']
  end

  def update_params
    params.permit(round_players: %i[id score goals missed_goals scored_penalty failed_penalty cleansheet
                                    assists yellow_card red_card own_goals caught_penalty missed_penalty
                                    played_minutes manual_lock])
  end

  def tournament_round
    @tournament_round ||= TournamentRound.find(params[:id])
  end
end
