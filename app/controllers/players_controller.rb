class PlayersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index leagues_list show]

  helper_method :league, :player, :tournament

  respond_to :html

  # Specify the layout for the index action
  layout 'react_application', only: [:index, :leagues_list]

  def index; end

  def leagues_list; end

  def show
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
    @player ||= Player.find(params[:id])
  end

  def league
    @league ||= League.find(params[:league_id])
  end

  def tournament
    stats_params[:tournament] ? Tournament.find(stats_params[:tournament]) : Tournament.first
  end
end
