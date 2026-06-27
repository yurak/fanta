class PlayersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index leagues_list]

  helper_method :league, :player, :tournament

  respond_to :html

  # Specify the layout for the index action
  layout 'react_application', only: %i[index leagues_list]

  def index; end

  def leagues_list; end

  def show
    redirect_to leagues_path unless player

    respond_to do |format|
      format.html do
        @stats = player.player_season_stats.joins(:tournament).includes(:season, :club)
                       .order(season_id: :desc, created_at: :desc)
        preload_player_show_associations
      end
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

  def preload_player_show_associations
    [
      player.season_club_in_squad.to_a,
      player.season_ec_in_squad.to_a,
      player.national_in_squad.to_a
    ].each do |rps|
      ActiveRecord::Associations::Preloader.new(records: rps, associations: %i[tournament_round club]).call
    end
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
