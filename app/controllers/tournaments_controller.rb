class TournamentsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  helper_method :fixtures, :national_fixtures, :tournament

  respond_to :html

  def show; end

  private

  def tournament
    @tournament ||= Tournament.find(params[:id])
  end

  def national_fixtures
    NationalMatch.where(tournament_round_id: tournament.tournament_rounds).group_by(&:tournament_round)
  end

  def fixtures
    TournamentMatch.where(tournament_round_id: tournament.tournament_rounds).group_by(&:tournament_round)
  end
end
