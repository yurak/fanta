module Players
  class Query < ApplicationService
    attr_reader :club_id, :direction, :field, :league_id, :max_app, :max_base_score,
                :max_price, :max_total_score, :max_teams_count, :min_app, :min_base_score,
                :min_price, :min_total_score, :min_teams_count, :name, :position,
                :team_id, :tournament_id, :without_team

    ASC_DIRECTION = 'asc'.freeze
    DESC_DIRECTION = 'desc'.freeze
    APPEARANCES = 'appearances'.freeze
    LEAGUE_PRICE = 'league_price'.freeze
    BASE_SCORE = 'base_score'.freeze
    CLUB = 'club'.freeze
    TOTAL_SCORE = 'total_score'.freeze
    POSITION = 'position'.freeze
    MAX_SEARCH = 100
    MIN_SEARCH = -100

    SQL_SORT_COLUMNS = {
      APPEARANCES => 'COALESCE(pss.played_matches, 0)',
      BASE_SCORE => 'COALESCE(pss.score, 0)',
      TOTAL_SCORE => 'COALESCE(pss.final_score, 0)'
    }.freeze

    def initialize(params) # rubocop:disable Metrics/MethodLength
      @club_id         = params[:club_id]
      @direction       = params[:direction] || DESC_DIRECTION
      @field           = params[:field]
      @league_id       = params[:league_id]
      @max_app         = params.dig(:app, :max)
      @max_base_score  = params.dig(:base_score, :max)
      @max_price       = params.dig(:price, :max)
      @max_total_score = params.dig(:total_score, :max)
      @min_app         = params.dig(:app, :min)
      @min_base_score  = params.dig(:base_score, :min)
      @min_price       = params.dig(:price, :min)
      @min_total_score  = params.dig(:total_score, :min)
      @min_teams_count  = params.dig(:teams_count, :min)
      @max_teams_count  = params.dig(:teams_count, :max)
      @name             = params[:name]
      @position        = params[:position]
      @team_id         = params[:team_id]
      @tournament_id   = params[:tournament_id]
      @without_team    = ActiveModel::Type::Boolean.new.cast(params[:without_team])
    end

    def call
      players = Player.by_tournament(tournament).by_club(club_ids).by_classic_position(position)
      players = join_season_stats(players)
      players = filter_by_name(players)
      players = filter_by_appearances(players)
      players = filter_by_base_score(players)
      players = filter_by_total_score(players)
      players = filter_by_teams_count(players)

      if needs_in_memory_filter?
        players = players.includes(:transfers, :teams, :player_season_stats, :club).to_a
        players = filter_by_team(players)
        players = filter_by_league_price(players)
        order_players_in_memory(players)
      else
        order_players_sql(players)
      end
    end

    private

    def join_season_stats(players)
      season_id = Season.last.id
      players.joins(
        "LEFT JOIN player_season_stats pss ON pss.player_id = players.id
         AND pss.season_id = #{season_id}
         AND pss.club_id = players.club_id"
      )
    end

    # --- SQL filtering ---

    def filter_by_name(players)
      return players unless name

      players.search_by_name(name)
    end

    def filter_by_appearances(players)
      players = players.where('COALESCE(pss.played_matches, 0) >= ?', min_app.to_f) if min_app
      players = players.where('COALESCE(pss.played_matches, 0) <= ?', max_app.to_f) if max_app
      players
    end

    def filter_by_base_score(players)
      players = players.where('COALESCE(pss.score, 0) >= ?', min_base_score.to_f) if min_base_score
      players = players.where('COALESCE(pss.score, 0) <= ?', max_base_score.to_f) if max_base_score
      players
    end

    def filter_by_total_score(players)
      players = players.where('COALESCE(pss.final_score, 0) >= ?', min_total_score.to_f) if min_total_score
      players = players.where('COALESCE(pss.final_score, 0) <= ?', max_total_score.to_f) if max_total_score
      players
    end

    def filter_by_teams_count(players)
      subquery = '(SELECT COUNT(*) FROM player_teams WHERE player_teams.player_id = players.id)'
      players = players.where("#{subquery} >= ?", min_teams_count.to_i) if min_teams_count
      players = players.where("#{subquery} <= ?", max_teams_count.to_i) if max_teams_count
      players
    end

    # --- In-memory filtering (league-specific, small dataset) ---

    def needs_in_memory_filter?
      league && (team_id.present? || without_team || min_price || max_price)
    end

    def filter_by_team(players)
      return players unless league && (team_id.present? || without_team)

      players.select { |pl| player_in_team?(pl) || player_without_team?(pl) }
    end

    def player_in_team?(player)
      team_id.present? && team_id.include?(player.team_by_league(league_id)&.id&.to_s)
    end

    def player_without_team?(player)
      without_team && player.team_by_league(league_id).nil?
    end

    def filter_by_league_price(players)
      return players unless league && (min_price || max_price)

      min = min_price.to_f
      max = max_price ? max_price.to_f : Float::INFINITY
      players.select { |pl| player_league_price(pl).between?(min, max) }
    end

    def player_league_price(player)
      team = player.team_by_league(league_id)
      team ? (player.transfer_by(team)&.price || 0) : 0
    end

    # --- SQL ordering ---

    def order_players_sql(players)
      return order_in_memory_from_sql(players) if in_memory_sort_from_sql?

      sql_dir = direction == ASC_DIRECTION ? 'ASC' : 'DESC'
      alpha_dir = direction == ASC_DIRECTION ? 'DESC' : 'ASC'

      if (sql_col = SQL_SORT_COLUMNS[field])
        players.order(Arel.sql("#{sql_col} #{sql_dir}"))
      elsif field == 'name'
        players.order(Arel.sql("players.name #{alpha_dir}"))
      elsif field == CLUB
        players.joins(:club).order(Arel.sql("clubs.name #{alpha_dir}"))
      else
        players.order(Arel.sql('COALESCE(pss.final_score, 0) DESC'))
      end
    end

    def in_memory_sort_from_sql?
      field == POSITION || (field == LEAGUE_PRICE && league)
    end

    def order_in_memory_from_sql(players)
      if field == POSITION
        order_players_in_memory(players.includes(:positions).to_a)
      else
        order_players_in_memory(players.includes(:transfers, :teams, :player_season_stats, :club).to_a)
      end
    end

    # --- In-memory ordering ---

    def order_players_in_memory(players)
      return players.sort_by { |p| -player_stat(p)&.final_score.to_f } unless field

      ordered = sort_in_memory(players)
      if alpha_field?
        direction == ASC_DIRECTION ? ordered.reverse : ordered
      else
        direction == ASC_DIRECTION ? ordered : ordered.reverse
      end
    end

    def alpha_field?
      field == CLUB || (field != POSITION && field != LEAGUE_PRICE && !SQL_SORT_COLUMNS.key?(field))
    end

    def sort_in_memory(players)
      return players.sort_by(&:position_sequence_number).reverse if field == POSITION

      players.sort_by { |p| sort_key_for(p) }
    end

    def sort_key_for(player)
      case field
      when CLUB then player.club&.name.to_s
      when LEAGUE_PRICE then player_league_price(player)
      else stat_sort_key_for(player)
      end
    end

    def stat_sort_key_for(player)
      stat = player_stat(player)
      case field
      when APPEARANCES then stat&.played_matches.to_i
      when BASE_SCORE  then stat&.score.to_f
      when TOTAL_SCORE then stat&.final_score.to_f
      else player.name.to_s
      end
    end

    def player_stat(player)
      player.player_season_stats.find { |s| s.club_id == player.club_id && s.season_id == current_season_id }
    end

    def current_season_id
      @current_season_id ||= Season.last&.id
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
