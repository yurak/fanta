module Tours
  class Dashboard < ApplicationService
    ACTIVE_STATUSES = %w[set_lineup locked postponed].freeze
    RECENT_CLOSED_WINDOW = 5.days
    STATUS_ORDER = %w[set_lineup locked postponed closed inactive].freeze

    def call
      counts   = grouped_counts
      inactive = first_inactive
      return [] if counts.empty? && inactive.empty?

      load_lookups(counts, inactive)
      build(counts, inactive)
    end

    private

    def grouped_counts
      Tour.joins(:tournament_round)
          .where(
            'tours.status IN (?) OR (tours.status = ? AND tours.updated_at >= ?)',
            ACTIVE_STATUSES.map { |status| Tour.statuses[status] },
            Tour.statuses[:closed],
            RECENT_CLOSED_WINDOW.ago
          )
          .group('tournament_rounds.tournament_id', :tournament_round_id, :status)
          .count
    end

    def first_inactive
      earliest = {}
      Tour.inactive.joins(:tournament_round)
          .group('tournament_rounds.tournament_id', :tournament_round_id, 'tournament_rounds.number')
          .count
          .each do |(tournament_id, round_id, number), count|
            current = earliest[tournament_id]
            earliest[tournament_id] = { round_id: round_id, number: number, count: count } if current.nil? || number < current[:number]
          end
      earliest
    end

    def load_lookups(counts, inactive)
      tournament_ids = counts.keys.map(&:first) + inactive.keys
      round_ids      = counts.keys.pluck(1) + inactive.values.pluck(:round_id)

      @tournaments = Tournament.where(id: tournament_ids.uniq).index_by(&:id)
      @rounds      = TournamentRound.where(id: round_ids.uniq).index_by(&:id)
    end

    def build(counts, inactive)
      nested = Hash.new { |hash, key| hash[key] = Hash.new { |inner, round_id| inner[round_id] = {} } }
      counts.each { |(tournament_id, round_id, status), count| nested[tournament_id][round_id][status] = count }
      inactive.each { |tournament_id, info| nested[tournament_id][info[:round_id]]['inactive'] = info[:count] }

      nested.filter_map { |tournament_id, rounds| tournament_entry(tournament_id, rounds) }
            .sort_by { |entry| entry[:tournament].id }
    end

    def tournament_entry(tournament_id, rounds)
      tournament = @tournaments[tournament_id]
      return unless tournament

      round_entries = rounds.filter_map { |round_id, status_counts| round_entry(round_id, status_counts) }
                            .sort_by { |entry| entry[:round].number }

      { tournament: tournament, rounds: round_entries } if round_entries.any?
    end

    def round_entry(round_id, status_counts)
      round = @rounds[round_id]
      return unless round

      { round: round, counts: ordered_counts(status_counts) }
    end

    def ordered_counts(status_counts)
      STATUS_ORDER.filter_map { |status| [status, status_counts[status]] if status_counts[status] }.to_h
    end
  end
end
