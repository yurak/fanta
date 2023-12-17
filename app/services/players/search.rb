module Players
  class Search < ApplicationService
    attr_reader :club_id, :league_id, :max_app, :max_base_score, :max_total_score, :min_app, :min_base_score, :min_total_score,
                :name, :position, :tournament_id

    MAX_SEARCH = 100
    MIN_SEARCH = -100
    ZERO_SEARCH = 0

    def initialize(params)
      @club_id = params[:club_id]
      @league_id = params[:league_id]
      @max_app = params[:max_app]
      @max_base_score = params[:max_base_score]
      @max_total_score = params[:max_total_score]
      @min_app = params[:min_app]
      @min_base_score = params[:min_base_score]
      @min_total_score = params[:min_total_score]
      @name = params[:name]
      @position = params[:position]
      @tournament_id = params[:tournament_id]
    end

    def call
      players = Player.by_tournament(tournament)
                      .by_club(club_ids)
                      .by_classic_position(position)

      players = search_by_name(players) if name
      players = search_by_appearances(players, min_app, max_app) if min_app || max_app
      players = search_by_base_score(players, min_base_score, max_base_score) if min_base_score || max_base_score
      players = search_by_total_score(players, min_total_score, max_total_score) if min_total_score || max_total_score
      players
    end

    private

    def search_by_name(players)
      Player.where(id: players.pluck(:id).uniq).search_by_name(name)
    end

    def search_by_appearances(players, min_value, max_value)
      max = max_value ? max_value.to_i : MAX_SEARCH
      min = min_value ? min_value.to_i : ZERO_SEARCH

      Player.where(id: players.select { |pl| pl.season_scores_count >= min && pl.season_scores_count <= max })
    end

    def search_by_base_score(players, min_value, max_value)
      max = max_value ? max_value.to_f : MAX_SEARCH
      min = min_value ? min_value.to_f : MIN_SEARCH

      Player.where(id: players.select { |pl| pl.season_average_score >= min && pl.season_average_score <= max })
    end

    def search_by_total_score(players, min_value, max_value)
      max = max_value ? max_value.to_f : MAX_SEARCH
      min = min_value ? min_value.to_f : MIN_SEARCH

      Player.where(id: players.select { |pl| pl.season_average_result_score >= min && pl.season_average_result_score <= max })
    end

    def club_ids
      return club_id if club_id.present?

      Club.active.by_tournament(tournament_ids).pluck(:id) if tournament_ids
    end

    def tournament_ids
      league ? league.tournament_id : @tournament_id
    end

    def tournament
      Tournament.find_by(id: league.tournament_id) if league
    end

    def league
      @league ||= League.find_by(id: league_id)
    end
  end
end
