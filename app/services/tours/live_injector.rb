module Tours
  class LiveInjector < ApplicationService
    CANDIDATE_WINDOW = 2.5.hours

    def initialize(tournament_round)
      @tournament_round = tournament_round
    end

    def call
      matches = live_matches
      return false if matches.empty?

      matches.each { |match| Scores::Injectors::FotmobMatch.call(match, run_mode: :live) }
      update_tours
      true
    end

    private

    attr_reader :tournament_round

    def live_matches
      round_matches.where.not(status: :finished)
                   .where.not(page_url: [nil, ''])
                   .select { |match| within_window?(match) }
    end

    def round_matches
      tournament_round.tournament.national? ? tournament_round.national_matches : tournament_round.tournament_matches
    end

    # Kickoff times for later rounds are often unknown (the calendar only carries them for the
    # first rounds and nothing refreshes them), so a match with no time is still polled — the
    # scrape itself gates on started/finished. A known time just narrows the poll to around kickoff.
    def within_window?(match)
      kickoff = match.utc_datetime
      return true if kickoff.nil?

      kickoff.between?(CANDIDATE_WINDOW.ago, 15.minutes.from_now)
    end

    def update_tours
      tournament_round.tours.each do |tour|
        Scores::PositionMalus::Updater.call(tour)
        Lineups::Updater.call(tour)
      end
    end
  end
end
