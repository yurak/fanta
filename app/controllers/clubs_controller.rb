class ClubsController < ApplicationController
  respond_to :html

  helper_method :club, :clubs, :league, :tournament

  def show
    redirect_to leagues_path unless club
  end

  private

  def club
    return @club if defined?(@club)

    @club = Club.includes(:tournament, players: :positions).find_by(id: params[:id])
  end

  def tournament
    @tournament ||= Tournament.find(params.expect(:tournament_id))
  end

  def league
    @league ||= League.find_by(id: params[:league_id]) ||
      current_user&.league_by_tournament(tournament.id) ||
      tournament.leagues.last
  end

  def clubs
    @clubs ||= tournament.eurocup ? tournament.ec_clubs.active.order(:name) : tournament.clubs.active.order(:name)
  end
end
