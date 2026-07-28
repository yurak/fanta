module Manage
  class LeagueStandings
    FINISHED_STATUSES = %w[locked closed postponed].freeze

    def initialize(league, ordered_results)
      @league = league
      @results = ordered_results.to_a
    end

    def lineup_pct(result)
      return 0 if finished_tours_count.zero?

      manual = manual_counts.fetch(result.team_id, 0)
      (manual.to_f / finished_tours_count * 100).round
    end

    def crownable?(result)
      return result.title_crownable? if result.title?
      return false unless @results.first&.id == result.id
      return true if @league.archived?
      return true if remaining_tours_count.zero?

      second = @results[1]
      return true if second.nil?

      result.points - second.points > remaining_tours_count * 3
    end

    private

    def tours
      @tours ||= @league.tours.to_a
    end

    def finished_tours
      @finished_tours ||= tours.select { |tour| FINISHED_STATUSES.include?(tour.status) }
    end

    def finished_tours_count
      finished_tours.size
    end

    def remaining_tours_count
      @remaining_tours_count ||= tours.count { |tour| !tour.closed? }
    end

    def manual_counts
      @manual_counts ||= compute_manual_counts
    end

    def compute_manual_counts
      tour_ids = finished_tours.map(&:id)
      team_ids = @results.map(&:team_id)
      return {} if tour_ids.empty? || team_ids.empty?

      Lineup.where(team_id: team_ids, tour_id: tour_ids, creation_type: %i[manual copied])
            .group(:team_id).count
    end
  end
end
