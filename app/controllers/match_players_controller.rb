class MatchPlayersController < ApplicationController
  respond_to :html, :json

  helper_method :match_player

  def update
    match_player.update(mp_params)

    redirect_to match_path(match_player.lineup.match)
  end

  private

  def identifier
    params[:match_player_id].presence || params[:id]
  end

  def match_player
    @match_player ||= MatchPlayer.find(identifier)
  end

  def mp_params
    params.permit(:cleansheet)
  end
end
