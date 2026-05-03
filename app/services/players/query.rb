module Players
  class Query < ApplicationService
    attr_reader :club_id, :direction, :field, :league_id, :max_app, :max_base_score,
                :max_total_score, :min_app, :min_base_score, :min_total_score,
                :name, :position, :team_id, :tournament_id, :without_team

    ASC_DIRECTION = 'asc'.freeze
    DESC_DIRECTION = 'desc'.freeze
    APPEARANCES = 'appearances'.freeze
    BASE_SCORE = 'base_score'.freeze
    CLUB = 'club'.freeze
    TOTAL_SCORE = 'total_score'.freeze
    POSITION = 'position'.freeze
    MAX_SEARCH = 100
    MIN_SEARCH = -100

    SORT_METHOD = {
      APPEARANCES => :season_scores_count,
      BASE_SCORE => :season_average_score,
      TOTAL_SCORE => :season_average_result_score,
      POSITION => :position_sequence_number
    }.freeze

    def initialize(params)
      @club_id         = params[:club_id]
      @direction       = params[:direction] || DESC_DIRECTION
      @field           = params[:field]
      @league_id       = params[:league_id]
      @max_app         = params.dig(:app, :max)
      @max_base_score  = params.dig(:base_score, :max)
      @max_total_score = params.dig(:total_score, :max)
      @min_app         = params.dig(:app, :min)
      @min_base_score  = params.dig(:base_score, :min)
      @min_total_score = params.dig(:total_score, :min)
      @name            = params[:name]
      @position        = params[:position]
      @team_id         = params[:team_id]
      @tournament_id   = params[:tournament_id]
      @without_team    = ActiveModel::Type::Boolean.new.cast(params[:without_team])
    end

    def call
      players = Player.by_tournament(tournament).by_club(club_ids).by_classic_position(position)
      players = filter_by_name(players)
      players = filter_by_appearances(players)
      players = filter_by_base_score(players)
      players = filter_by_total_score(players)
      players = filter_by_team(players)
      order_players(players)
    end

    private

    # --- Filtering ---

    def filter_by_name(players)
      return players unless name

      Player.where(id: players.distinct.pluck(:id)).search_by_name(name)
    end

    def filter_by_appearances(players)
      filter_by_range(players, :season_scores_count, min_app, max_app, default_min: 0)
    end

    def filter_by_base_score(players)
      filter_by_range(players, :season_average_score, min_base_score, max_base_score)
    end

    def filter_by_total_score(players)
      filter_by_range(players, :season_average_result_score, min_total_score, max_total_score)
    end

    def filter_by_range(players, attr, min_val, max_val, default_min: MIN_SEARCH)
      return players unless min_val || max_val

      min = min_val ? min_val.to_f : default_min
      max = max_val ? max_val.to_f : MAX_SEARCH
      Player.where(id: players.select { |pl| pl.public_send(attr).between?(min, max) })
    end

    def filter_by_team(players)
      return players unless league && (team_id.present? || without_team)

      player_ids = filter_by_team_id(players) + filter_without_team(players)
      Player.where(id: player_ids)
    end

    def filter_by_team_id(players)
      return [] unless team_id

      players.select { |pl| team_id.include?(pl.team_by_league(league_id)&.id&.to_s) }.pluck(:id)
    end

    def filter_without_team(players)
      return [] unless without_team

      players.select { |pl| pl.team_by_league(league_id).nil? }.pluck(:id)
    end

    # --- Ordering ---

    def order_players(players)
      return players.to_a unless field

      ordered = build_order(players)
      direction == ASC_DIRECTION ? ordered.reverse : ordered
    end

    def build_order(players)
      return club_order(players) if field == CLUB
      return players.sort_by(&:name) unless SORT_METHOD.key?(field)

      players.sort_by(&SORT_METHOD[field]).reverse
    end

    def club_order(players)
      players.includes(:club).order('clubs.name').to_a
    end

    # --- Helpers ---

    def club_ids
      return club_id if club_id.present?

      Club.active.by_tournament(tournament_id_for_filter).pluck(:id) if tournament_id_for_filter
    end

    def tournament_id_for_filter
      league ? league.tournament_id : tournament_id
    end

    def tournament
      @tournament ||= Tournament.find_by(id: league.tournament_id) if league
    end

    def league
      return @league if defined?(@league)

      @league = League.find_by(id: league_id)
    end
  end
end
