module TournamentMatches
  class CalendarImporter < ApplicationService
    attr_reader :tournament, :season

    def initialize(tournament, season: Season.last)
      @tournament = tournament
      @season = season
    end

    def call
      return empty_result unless tournament && season

      entries = numbered(TournamentRounds::FotmobCalendarParser.call(tournament))
      return empty_result if entries.empty?

      entries.each { |entry| import(entry) }
      result
    end

    private

    def numbered(entries)
      return [] if entries.empty?
      return entries.map { |entry| entry.merge(round_number: entry[:round_name].to_i) } unless tournament.fanta?

      days = entries.map { |entry| entry[:kickoff].to_date }.uniq.sort
      entries.map { |entry| entry.merge(round_number: days.index(entry[:kickoff].to_date) + 1) }
    end

    def import(entry)
      round = rounds[entry[:round_number]]
      return missing_round(entry) unless round

      match = TournamentMatch.find_or_initialize_by(source_match_id: entry[:source_match_id])
      new_record = match.new_record?
      match.assign_attributes(attributes_for(entry, round, new_record))

      count(save_outcome(match, new_record))
      track_unknown_clubs(entry)
    end

    def save_outcome(match, new_record)
      return :failed unless match.save

      new_record ? :created : :updated
    end

    def attributes_for(entry, round, new_record)
      attributes = {
        tournament_round: round, host_club: club(entry[:home_name]), guest_club: club(entry[:away_name]),
        page_url: entry[:page_url], round_name: entry[:round_number],
        time: entry[:kickoff].strftime('%H:%M'), date: entry[:kickoff].strftime('%^b %e, %Y')
      }
      new_record ? attributes.merge(score_attributes(entry)) : attributes
    end

    def score_attributes(entry)
      scores = entry[:score].to_s.split('-').map(&:strip)
      return {} unless scores.size == 2

      { host_score: scores[0], guest_score: scores[1] }
    end

    def rounds
      @rounds ||= tournament.tournament_rounds.by_season(season.id).index_by(&:number)
    end

    def club(name)
      return nil if name.blank?

      @clubs ||= {}
      @clubs[name] ||= Club.find_by(name: name) || Club.find_by(full_name: name)
    end

    def track_unknown_clubs(entry)
      [entry[:home_name], entry[:away_name]].compact_blank.each do |name|
        unknown_clubs << name unless club(name)
      end
    end

    def missing_round(entry)
      missing_rounds << entry[:round_number]
      count(:skipped)
    end

    def count(key)
      counts[key] += 1
    end

    def counts
      @counts ||= Hash.new(0)
    end

    def unknown_clubs
      @unknown_clubs ||= Set.new
    end

    def missing_rounds
      @missing_rounds ||= Set.new
    end

    def result
      { created: counts[:created], updated: counts[:updated], skipped: counts[:skipped],
        failed: counts[:failed], unknown_clubs: unknown_clubs.to_a.sort,
        missing_rounds: missing_rounds.to_a.sort }
    end

    def empty_result
      { created: 0, updated: 0, skipped: 0, failed: 0, unknown_clubs: [], missing_rounds: [] }
    end
  end
end
