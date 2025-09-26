class TournamentMatchesController < ApplicationController
  respond_to :html

  helper_method :tournament_match

  def edit; end

  def update
    if (can? :update, TournamentMatch) && tournament_match.update(tournament_match_params)
      redirect_to tournament_round_path(tournament_match.tournament_round)
    else
      render :edit
    end
  end

  private

  def tournament_match_params
    params.require(:tournament_match).permit(
      :host_score,
      :guest_score,
      :source_match_id,
      :time,
      :date,
      :round_name,
      :page_url,
      :base_data,
      :lineups_data
    )
  end

  def tournament_match
    @tournament_match ||= TournamentMatch.find(params[:id])
  end
end
