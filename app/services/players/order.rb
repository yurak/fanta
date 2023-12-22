module Players
  class Order < ApplicationService
    attr_reader :direction, :field, :players

    ASC_DIRECTION = 'asc'.freeze
    DESC_DIRECTION = 'desc'.freeze
    APPEARANCES = 'appearances'.freeze
    BASE_SCORE = 'base_score'.freeze
    CLUB = 'club'.freeze
    TOTAL_SCORE = 'total_score'.freeze
    POSITION = 'position'.freeze

    SORT_METHOD = {
      APPEARANCES => :season_scores_count,
      BASE_SCORE => :season_average_score,
      TOTAL_SCORE => :season_average_result_score,
      POSITION => :position_sequence_number
    }.freeze

    def initialize(players, params)
      @players = players
      @direction = params[:direction] || DESC_DIRECTION
      @field = params[:field]
    end

    def call
      ordered_players = order
      ordered_players = ordered_players.reverse if direction == ASC_DIRECTION
      ordered_players
    end

    private

    def order
      return club_order if field == CLUB
      return name_order if SORT_METHOD.keys.exclude?(field)

      players.sort_by(&SORT_METHOD[field]).reverse
    end

    def name_order
      players.sort_by(&:name)
    end

    def club_order
      players.includes(:club).order('clubs.name')
    end
  end
end
