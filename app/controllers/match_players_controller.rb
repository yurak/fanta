class MatchPlayersController < ApplicationController
  respond_to :html, :json

  helper_method :match_player

  def update
    match_player.update(mp_params) if can? :update, MatchPlayer

    redirect_to match_path(match_player.lineup.match)
  end

  private

  def match_player
    @match_player ||= MatchPlayer.find(params[:id])
  end

  def mp_params
    params.permit(:cleansheet)
  end
end
