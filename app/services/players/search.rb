module Players
  class Search < ApplicationService
    attr_reader :club_id, :league_id, :max_app, :max_base_score, :max_total_score, :min_app, :min_base_score, :min_total_score,
                :name, :position, :team_id, :tournament_id, :without_team

    MAX_SEARCH = 100
    MIN_SEARCH = -100
    ZERO_SEARCH = 0

    def initialize(params)
      @club_id = params[:club_id]
      @league_id = params[:league_id]
      @max_app = params.dig(:app, :max)
      @max_base_score = params.dig(:base_score, :max)
      @max_total_score = params.dig(:total_score, :max)
      @min_app = params.dig(:app, :min)
      @min_base_score = params.dig(:base_score, :min)
      @min_total_score = params.dig(:total_score, :min)
      @name = params[:name]
      @position = params[:position]
      @team_id = params[:team_id]
      @tournament_id = params[:tournament_id]
      @without_team = ActiveModel::Type::Boolean.new.cast(params[:without_team])
    end

    def call
      players = Player.by_tournament(tournament).by_club(club_ids).by_classic_position(position)
      players = search_by_name(players)
      players = search_by_appearances(players)
      players = search_by_base_score(players)
      players = search_by_total_score(players)
      search_by_team(players)
    end

    private

    def search_by_name(players)
      return players unless name

      Player.where(id: players.pluck(:id).uniq).search_by_name(name)
    end

    def search_by_appearances(players)
      return players unless min_app || max_app

      max = max_app ? max_app.to_i : MAX_SEARCH
      min = min_app ? min_app.to_i : ZERO_SEARCH

      Player.where(id: players.select { |pl| pl.season_scores_count >= min && pl.season_scores_count <= max })
    end

    def search_by_base_score(players)
      return players unless min_base_score || max_base_score

      max = max_base_score ? max_base_score.to_f : MAX_SEARCH
      min = min_base_score ? min_base_score.to_f : MIN_SEARCH

      Player.where(id: players.select { |pl| pl.season_average_score >= min && pl.season_average_score <= max })
    end

    def search_by_total_score(players)
      return players unless min_total_score || max_total_score

      max = max_total_score ? max_total_score.to_f : MAX_SEARCH
      min = min_total_score ? min_total_score.to_f : MIN_SEARCH

      Player.where(id: players.select { |pl| pl.season_average_result_score >= min && pl.season_average_result_score <= max })
    end

    def search_by_team(players)
      return players unless league && (team_id.present? || without_team)

      players_ids = search_by_team_id(players) + search_without_team(players)

      Player.where(id: players_ids)
    end

    def search_by_team_id(players)
      return [] unless team_id

      players.select { |pl| team_id.include?(pl.team_by_league(league_id)&.id&.to_s) }.pluck(:id)
    end

    def search_without_team(players)
      return [] unless without_team

      players.select { |pl| pl.team_by_league(league_id).nil? }.pluck(:id)
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
