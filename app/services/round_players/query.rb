module RoundPlayers
  class Query < ApplicationService
    ASC_DIRECTION = 'asc'.freeze
    DESC_DIRECTION = 'desc'.freeze

    NAME = 'name'.freeze
    CLUB = 'club'.freeze
    BASE_SCORE = 'base_score'.freeze
    APPEARANCES = 'appearances'.freeze
    MAIN_APPEARANCES = 'main_appearances'.freeze

    PLAYER_PRELOADS = { player: %i[player_positions positions national_team club] }.freeze

    attr_reader :tournament_round_id, :position, :club_id, :league_id, :name, :field, :direction

    def initialize(params)
      @tournament_round_id = params[:tournament_round_id]
      @position            = params[:position]
      @club_id             = params[:club_id]
      @league_id           = params[:league_id]
      @name                = params[:name]
      @field               = params[:field]
      @direction           = params[:direction] || DESC_DIRECTION
    end

    # The set of round players shown before any position/club/name filter.
    # Shared with the controller so the club filter dropdown lists exactly the
    # clubs (or national teams) present in this set — e.g. eurocup rounds use
    # eurocup_players (the participating ec_clubs), not all round players.
    def self.base_scope_for(tournament_round)
      tournament = tournament_round.tournament

      if tournament.national?
        tournament_round.round_players
      elsif tournament.eurocup?
        tournament_round.eurocup_players
      else
        tournament_round.round_players.with_score
      end
    end

    def call
      players = base_scope
      players = filter_by_position(players)
      players = filter_by_club(players)
      players = filter_by_name(players)

      sort_players(preload(players.to_a))
    end

    private

    def base_scope
      self.class.base_scope_for(tournament_round)
    end

    # The React positions filter sends classic codes (GK, CB, ...), which map to
    # Position#human_name (vs. the Italian Position#name).
    def filter_by_position(players)
      return players if position.blank?

      players.where(player_id: Player.by_classic_position(position))
    end

    # On national rounds the filter values are national team ids; otherwise
    # they are club ids. Matches how the round entities are exposed by the meta
    # endpoint (see Api::RoundPlayersController#clubs_payload).
    def filter_by_club(players)
      return players if club_id.blank?

      if tournament.national?
        players.where(player_id: Player.where(national_team_id: club_id))
      else
        players.where(player_id: Player.where(club_id: club_id))
      end
    end

    def filter_by_name(players)
      return players if name.blank?

      players.where(player_id: Player.search_by_name(name))
    end

    # --- Preloading ---

    def preload(players)
      preloader = ActiveRecord::Associations::Preloader.new
      preloader.preload(players, PLAYER_PRELOADS)
      preloader.preload(players, :club)
      preload_match_players(players)
      players
    end

    def preload_match_players(players)
      scope = league_id.present? ? MatchPlayer.by_league(league_id) : nil
      ActiveRecord::Associations::Preloader.new.preload(players, :match_players, scope)
    end

    # --- In-memory ordering ---

    def sort_players(players)
      case sort_field
      when NAME             then sort_alpha(players, &:name)
      when CLUB             then sort_alpha(players) { |rp| rp.related_club.name.to_s }
      when BASE_SCORE       then sort_numeric(players) { |rp| rp.score.to_f }
      when APPEARANCES      then sort_numeric(players) { |rp| rp.match_players.size }
      when MAIN_APPEARANCES then sort_numeric(players) { |rp| rp.match_players.count(&:real_position) }
      else                       sort_numeric(players, &:result_score)
      end
    end

    # Appearance-based sorting is only meaningful once the round is deadlined;
    # before that it falls back to the default ordering.
    def sort_field
      return nil if [APPEARANCES, MAIN_APPEARANCES].include?(field) && !deadlined?

      field
    end

    def deadlined?
      return @deadlined if defined?(@deadlined)

      @deadlined = tournament_round.tours.last&.deadlined? || false
    end

    def sort_numeric(players, &key)
      sorted = players.sort_by(&key)
      ascending? ? sorted : sorted.reverse
    end

    def sort_alpha(players, &key)
      sorted = players.sort_by(&key)
      ascending? ? sorted : sorted.reverse
    end

    def ascending?
      direction == ASC_DIRECTION
    end

    def tournament_round
      @tournament_round ||= TournamentRound.find(tournament_round_id)
    end

    def tournament
      @tournament ||= tournament_round.tournament
    end
  end
end
