class SubstitutesController < ApplicationController
  respond_to :html

  helper_method :lineup, :match_player

  def new
    redirect_to match_path(lineup.match) unless sub_available?
  end

  def create
    if (can? :create, Substitute) && call_subs_creator
      redirect_to match_path(lineup.match)
    else
      redirect_to new_match_player_substitute_path(match_player)
    end
  end

  def destroy
    call_subs_destroyer if can? :destroy, Substitute

    redirect_to match_path(lineup.match)
  end

  private

  def permit_params
    params.permit(:id, :match_player_id, :reserve_mp_id)
  end

  def call_subs_creator
    Substitutes::Creator.call(permit_params[:match_player_id], permit_params[:reserve_mp_id])
  end

  def call_subs_destroyer
    Substitutes::Destroyer.call(permit_params[:id])
  end

  def sub_available?
    lineup.tour.locked_or_postponed? && match_player.not_played? && (can? :new, Substitute)
  end

  def match_player
    @match_player ||= MatchPlayer.find(permit_params[:match_player_id])
  end

  def lineup
    @lineup ||= match_player&.lineup
  end
end
