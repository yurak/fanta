class PlayersController < ApplicationController
  helper_method :league, :player, :tournament

  respond_to :html

  # Specify the layout for the index action
  layout 'react_application', only: [:index]

  def index; end

  def show
    redirect_to leagues_path unless player

    @stats = player.player_season_stats.joins(:season, :club, :tournament).order(season_id: :desc, created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: player, serializer: PlayerLineupSerializer }
    end
  end

  def update
    player.teams.each { |team| Transfers::Seller.call(player, team, :left) } if can? :update, Player

    redirect_to player_path(player)
  end

  private

  def player
    return @player if defined?(@player)

    @player = Player.includes(transfers: :auction).find_by(id: params[:id])
  end

  def stats_params
    params.permit(:club, :order, :position, :tournament, :search, :league)
  end

  def tournament
    tournament = Tournament.find_by(id: stats_params[:tournament])
    tournament ||= Tournament.first
    tournament
  end

  def league
    league = League.find_by(id: stats_params[:league])
    league ||= tournament.leagues.active.first
    league
  end
end
