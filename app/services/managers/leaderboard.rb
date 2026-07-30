module Managers
  class Leaderboard < ApplicationService
    METRICS = %w[win_rate avg_total_score titles matches].freeze
    ARCHIVED = League.statuses[:archived]

    Entry = Struct.new(:user_id, :value, :matches, :champion_number, :rank, keyword_init: true)

    def initialize(metric: nil, include_newbies: false, min_matches: 0, tournament_id: nil)
      @metric = METRICS.include?(metric.to_s) ? metric.to_s : METRICS.first
      @include_newbies = ActiveModel::Type::Boolean.new.cast(include_newbies) || false
      @min_matches = min_matches.to_i
      @tournament_id = tournament_id.presence
    end

    def call
      ranked
    end

    def entry_for(user_id)
      return unless user_id

      ranked.find { |entry| entry.user_id == user_id }
    end

    private

    attr_reader :metric, :include_newbies, :min_matches, :tournament_id

    def ranked
      @ranked ||= begin
        entries = build_entries
        entries.sort_by! { |entry| sort_key(entry) }
        entries.each_with_index { |entry, index| entry.rank = index + 1 }
        entries
      end
    end

    def build_entries
      base_stats.filter_map do |user_id, stat|
        next unless included?(stat)

        value = value_for(user_id, stat)
        next if metric == 'titles' && value.zero?

        Entry.new(user_id: user_id, value: value, matches: stat[:matches],
                  champion_number: (champion_numbers[user_id] if metric == 'titles'))
      end
    end

    def included?(stat)
      return false if !include_newbies && stat[:finished].zero?

      stat[:matches] >= min_matches
    end

    # Titles: more titles first, then the earlier champion (smaller number) first.
    # Other metrics: value first, then more matches first.
    def sort_key(entry)
      return [-entry.value, entry.champion_number || Float::INFINITY, entry.user_id] if metric == 'titles'

      [-entry.value, -entry.matches, entry.user_id]
    end

    def value_for(user_id, stat)
      case metric
      when 'avg_total_score' then avg_ts_map[user_id] || 0.0
      when 'titles' then titles_map[user_id] || 0
      when 'matches' then stat[:matches]
      else win_rate(stat)
      end
    end

    def win_rate(stat)
      return 0.0 if stat[:matches].zero?

      (stat[:wins] * 100.0 / stat[:matches]).round(2)
    end

    # { user_id => { wins:, matches:, finished: } } across mantra, non-demo results.
    def base_stats
      @base_stats ||= begin
        relation = Result.mantra.where(leagues: { demo: false }).joins(:team).where.not(teams: { user_id: nil })
        relation = relation.where(leagues: { tournament_id: tournament_id }) if tournament_id

        relation.group('teams.user_id')
                .pluck(
                  Arel.sql('teams.user_id'),
                  Arel.sql('SUM(results.wins)'),
                  Arel.sql('SUM(results.wins + results.draws + results.loses)'),
                  Arel.sql("SUM(CASE WHEN leagues.status = #{ARCHIVED} THEN 1 ELSE 0 END)")
                )
                .to_h { |user_id, wins, matches, finished| [user_id, stat_row(wins, matches, finished)] }
      end
    end

    def stat_row(wins, matches, finished)
      { wins: wins.to_i, matches: matches.to_i, finished: finished.to_i }
    end

    def avg_ts_map
      @avg_ts_map ||= begin
        relation = Lineup.finished.mantra.where(tour_id: non_demo_tour_ids).joins(:team)
        relation = relation.where(tournaments: { id: tournament_id }) if tournament_id

        relation.group('teams.user_id').average(:final_score).transform_values { |avg| avg.to_f.round(2) }
      end
    end

    def titles_map
      relation = tournament_id ? UserTitle.where(tournament_id: tournament_id) : UserTitle
      @titles_map ||= relation.group(:user_id).count
    end

    def champion_numbers
      @champion_numbers ||= User.where(id: base_stats.keys).pluck(:id, :champion_number).to_h
    end

    def non_demo_tour_ids
      Tour.joins(:league).where(leagues: { demo: false }).select(:id)
    end
  end
end
