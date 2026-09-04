module Tours
  class LiveInjector < ApplicationService
    CANDIDATE_WINDOW = 2.5.hours

    def initialize(tournament_round, budget: Scores::ScrapeBudget.new)
      @tournament_round = tournament_round
      @budget = budget
    end

    def call
      matches = live_matches
      return { candidates: 0, with_data: 0, failures: 0 } if matches.empty?

      results = matches.map { |match| run_injector(match) }
      with_data = results.count { |result| result[:data] }
      # nothing came back from the source, so no score changed — recomputing every tour of the round
      # (dozens of leagues) would burn a whole cron pass for nothing
      update_tours if with_data.positive?

      { candidates: matches.size, with_data: with_data, failures: results.count { |result| result[:failure] } }
    end

    private

    attr_reader :tournament_round

    # One failing match must not take the rest of the round — or the rounds after it — down with it:
    # the source raises in ways the injector cannot foresee (an unlisted network errno, broken gzip,
    # a write that blows up), and this runs unattended from cron. The counts are read here rather
    # than from the injector afterwards: a crash can leave it without memoized data, and asking it
    # again would re-issue the request that just failed.
    def run_injector(match)
      injector = Scores::Injectors::FotmobMatch.new(match, run_mode: :live, budget: @budget)
      injector.call
      { data: injector.data_available?, failure: injector.scrape_health_failure? }
    rescue StandardError => e
      Rollbar.error(e, match_id: match.id, page_url: match.page_url, tournament_round_id: tournament_round.id)
      Rails.logger.error("[live-scores] injector crashed for #{match.page_url}: #{e.class}: #{e.message}")
      { data: false, failure: true }
    end

    def live_matches
      tournament_round.matches
                      .where.not(status: :finished)
                      .where.not(page_url: [nil, ''])
                      .select { |match| within_window?(match) }
    end

    def within_window?(match)
      return true if match.live?

      kickoff = match.utc_datetime
      return true if kickoff.nil?

      kickoff.between?(CANDIDATE_WINDOW.ago, 15.minutes.from_now)
    end

    def update_tours
      tournament_round.tours.each do |tour|
        Scores::PositionMalus::Updater.call(tour)
        Lineups::Updater.call(tour)
      rescue StandardError => e
        Rollbar.error(e, tour_id: tour.id, tournament_round_id: tournament_round.id)
        Rails.logger.error("[live-scores] tour recompute crashed for tour #{tour.id}: #{e.class}: #{e.message}")
      end
    end
  end
end
