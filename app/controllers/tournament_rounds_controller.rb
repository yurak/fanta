class TournamentRoundsController < ApplicationController
  respond_to :html, :json

  helper_method :tournament_round

  def edit_scores
    redirect_to leagues_path unless current_user&.can_moderate?

    @round_players = if params[:club_id]
                       tournament_round.round_players.by_club(params[:club_id]).ordered_by_club
                     else
                       tournament_round.round_players.ordered_by_club
                     end
    respond_with tournament_round
  end

  def update_scores
    round_players = update_params['round_players']
    round_players.keys.each do |rp_id|
      rp = RoundPlayer.find(rp_id.to_i)
      rp.update_attributes(round_players[rp_id].to_hash)
    end
    redirect_to leagues_path
  end

  private

  def update_params
    params.permit(round_players: %i[id score goals missed_goals scored_penalty failed_penalty
                                    assists yellow_card red_card own_goals caught_penalty missed_penalty])
  end

  def identifier
    params[:tournament_round_id].presence || params[:id]
  end

  def tournament_round
    @tournament_round ||= TournamentRound.find(identifier)
  end
end
