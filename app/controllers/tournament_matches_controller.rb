class TournamentMatchesController < ApplicationController
  respond_to :html

  helper_method :tournament_match

  def edit
    redirect_to leagues_path unless can? :edit, TournamentMatch
  end

  def update
    if can? :update, TournamentMatch
      if tournament_match.update(tournament_match_params)
        redirect_to tournament_round_path(tournament_match.tournament_round)
      else
        render :edit
      end
    else
      redirect_to leagues_path
    end
  end

  private

  def tournament_match_params
    params.expect(
      tournament_match: %i[
        host_score
        guest_score
        source_match_id
        time
        date
        round_name
        page_url
        base_data
        lineups_data
      ]
    )
  end

  def tournament_match
    @tournament_match ||= TournamentMatch.find(params.expect(:id))
  end
end
