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
      case field
      when APPEARANCES
        players.sort_by(&:season_scores_count).reverse
      when BASE_SCORE
        players.sort_by(&:season_average_score).reverse
      when CLUB
        players.includes(:club).order('clubs.name')
      when TOTAL_SCORE
        players.sort_by(&:season_average_result_score).reverse
      when POSITION
        players.sort_by(&:position_sequence_number).reverse
      else
        players.sort_by(&:name)
      end
    end
  end
end
