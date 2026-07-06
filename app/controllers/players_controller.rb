class PlayersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index leagues_list]

  helper_method :league, :player, :tournament

  respond_to :html

  # Specify the layout for the React-rendered actions
  layout 'react_application', only: %i[index leagues_list show]

  def index; end

  def leagues_list; end

  def show
    return redirect_to leagues_path unless player

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

    @player = Player.includes(
      :positions,
      transfers: :auction,
      teams: { league: :division },
      club: :tournament
    ).find_by(id: params[:id])
  end

  def stats_params
    params.permit(:club, :order, :position, :tournament, :search, :league)
  end

  def league
    return @league if defined?(@league)

    @league = if params[:league_id] || params[:id]
                League.find_by(id: params[:league_id] || params[:id])
              else
                League.find_by(id: stats_params[:league]) || (tournament && tournament.leagues.active.first)
              end
  end

  def tournament
    tournament = Tournament.find_by(id: stats_params[:tournament])
    tournament ||= Tournament.first
    tournament
  end
end
