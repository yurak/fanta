module Api
  class PlayersController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index show]

    respond_to :json

    helper_method :player

    def index
      players = Kaminari.paginate_array(ordered_players).page(page[:number]).per(page[:size])

      players_ser = players.map { |l| PlayerBaseSerializer.new(l, league_id: filter_params[:league_id]) }
      render json: { data: players_ser, meta: response_options(players) }
    end

    def show
      if player
        render json: { data: PlayerSerializer.new(player) }
      else
        not_found
      end
    end

    private

    def player
      @player ||= Player.find_by(id: params[:id])
    end

    def filtered_players
      Players::Search.call(filter_params)
    end

    def ordered_players
      Players::Order.call(filtered_players, order_params)
    end

    def filter_params
      params.fetch(:filter, {})
            .permit(:league_id, :max_app, :min_app, :name,
                    position: [], tournament_id: [], club_id: [])
    end

    def order_params
      params.fetch(:order, {}).permit(:direction, :field)
    end
  end
end
