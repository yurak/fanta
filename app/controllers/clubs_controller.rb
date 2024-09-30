class ClubsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show]

  respond_to :html

  helper_method :club, :clubs, :league, :tournament

  def show; end

  private

  def club
    @club ||= Club.find(params[:id])
  end

  def tournament
    @tournament ||= Tournament.find(params[:tournament_id])
  end

  def league
    @league ||= League.find_by(id: params[:league_id]) || tournament.leagues.last
  end

  def clubs
    @clubs ||= tournament.eurocup ? tournament.ec_clubs.active.order(:name) : tournament.clubs.active.order(:name)
  end
end
