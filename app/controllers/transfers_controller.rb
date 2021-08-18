class TransfersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index]

  respond_to :html

  helper_method :league, :player, :players

  def index
    @transfers = Kaminari.paginate_array(league.transfers.reverse).page(params[:page])
  end

  def auction
    redirect_to league_transfers_path(league) unless can? :auction, Transfer
  end

  def create
    if (can? :create, Transfer) && valid_transfer?
      ActiveRecord::Base.transaction do
        league.transfers.create(create_params)
        PlayerTeam.create(team: team, player_id: create_params[:player_id])
        team.update(budget: team.budget - price)
      end
    elsif transfer_player && !transfer_player.team_by_league(league.id)
      player = transfer_player.id
    end

    redirect_to league_auction_path(league, player: player)
  end

  def destroy
    transfer = Transfer.find_by(id: params[:id])

    if (can? :destroy, Transfer) && transfer
      ActiveRecord::Base.transaction do
        transfer.team.update(budget: transfer.team.budget + transfer.price)
        PlayerTeam.find_by(team: transfer.team, player: transfer.player).destroy
        transfer.destroy
      end
    end

    redirect_to league_auction_path(league)
  end

  private

  def league
    @league ||= League.find(params[:league_id])
  end

  def player
    @player = Player.find_by(id: params[:player])
  end

  def transfer_player
    @transfer_player = Player.find_by(id: create_params[:player_id])
  end

  def players
    @players = Player.by_tournament(league.tournament).search_by_name(params[:search]) if params[:search].present?
  end

  def team
    @team ||= Team.find_by(id: create_params[:team_id])
  end

  def price
    create_params[:price].to_i
  end

  def create_params
    return nil unless params[:transfer]

    params.require(:transfer).permit(:player_id, :team_id, :price)
  end

  def valid_transfer?
    return false unless transfer_player
    return false unless team
    return false if team.vacancies.zero?
    return false if price > team.max_rate || price < 1
    return false if transfer_player&.team_by_league(league.id)

    true
  end
end
