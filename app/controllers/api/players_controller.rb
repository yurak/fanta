module Api
  class PlayersController < Api::ApplicationController
    skip_before_action :authenticate_user!, only: %i[index show stats]

    respond_to :json

    helper_method :player

    def index
      result = Players::Query.call(query_params)
      players = paginate(result)
      preload_associations(players.to_a)
      players_ser = players.map { |l| PlayerBaseSerializer.new(l, league_id: filter_params[:league_id]) }
      render json: { data: players_ser, meta: response_options(players) }
    end

    def show
      if player
        preload_show_associations
        render json: { data: PlayerSerializer.new(player) }
      else
        not_found
      end
    end

    def stats
      if player
        preload_stats_associations
        render json: { data: PlayerStatsSerializer.new(player, season: stats_season) }
      else
        not_found
      end
    end

    private

    def stats_season
      return @stats_season if defined?(@stats_season)

      @stats_season = (params[:season_id] && Season.find_by(id: params[:season_id])) || player.current_season
    end

    def player
      return @player if defined?(@player)

      @player = Player.find_by(id: params[:id])
    end

    def preload_show_associations
      ActiveRecord::Associations::Preloader.new(
        records: [player],
        associations: [
          { club: :tournament },
          { club_transfers: %i[old_club new_club] },
          { teams: { league: :division } },
          { transfers: :auction },
          { player_positions: :position },
          :player_season_stats,
          :national_team
        ]
      ).call

      # Banner score (season_score) iterates these round players and reads tournament_round
      ActiveRecord::Associations::Preloader.new(
        records: player.season_club_matches_w_scores.to_a, associations: :tournament_round
      ).call
    end

    def preload_stats_associations
      [
        player.club_in_squad_for(stats_season),
        player.ec_in_squad_for(stats_season),
        player.national_in_squad_for(stats_season)
      ].each do |round_players|
        ActiveRecord::Associations::Preloader.new(
          records: round_players.to_a, associations: %i[club tournament_round]
        ).call
      end

      ActiveRecord::Associations::Preloader.new(
        records: [player], associations: { player_season_stats: %i[season club] }
      ).call
    end

    def query_params
      filter_params.merge(order_params)
    end

    def filter_params
      params.fetch(:filter, {})
            .permit(:league_id, :name, :without_team,
                    app: {}, base_score: {}, minutes: {}, price: {}, teams_count: {}, total_score: {},
                    club_id: [], position: [], team_id: [], tournament_id: [])
    end

    def order_params
      params.fetch(:order, {}).permit(:direction, :field)
    end

    def preload_associations(records)
      ActiveRecord::Associations::Preloader.new(records: records, associations: :transfers).call
      ActiveRecord::Associations::Preloader.new(records: records, associations: :player_season_stats).call
      ActiveRecord::Associations::Preloader.new(records: records, associations: { club: :tournament }).call
      ActiveRecord::Associations::Preloader.new(records: records, associations: { player_positions: :position }).call
      ActiveRecord::Associations::Preloader.new(records: records, associations: :teams).call
    end
  end
end
