module Api
  class PlayersController < Api::ApplicationController
    skip_before_action :authenticate_user!, only: %i[index show stats]

    respond_to :json

    helper_method :player

    def index
      result = Players::Query.call(query_params)
      players = if page.present?
                  Kaminari.paginate_array(result).page(page[:number]).per(page[:size])
                else
                  Kaminari.paginate_array(result).page(1).per(result.size)
                end
      ActiveRecord::Associations::Preloader.new.preload(players.to_a, [:transfers, { club: :tournament }, { player_positions: :position }])
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

    def stats
      if player
        render json: { data: PlayerStatsSerializer.new(player) }
      else
        not_found
      end
    end

    private

    def player
      @player ||= Player.find_by(id: params[:id])
    end

    def query_params
      filter_params.merge(order_params)
    end

    def filter_params
      params.fetch(:filter, {})
            .permit(:league_id, :name, :without_team,
                    app: {}, base_score: {}, total_score: {},
                    club_id: [], position: [], team_id: [], tournament_id: [])
    end

    def order_params
      params.fetch(:order, {}).permit(:direction, :field)
    end
  end
end
