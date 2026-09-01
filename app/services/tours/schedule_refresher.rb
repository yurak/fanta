module Tours
  class ScheduleRefresher < ApplicationService
    def initialize(tournament_round, budget: Scores::ScrapeBudget.new)
      @tournament_round = tournament_round
      @budget = budget
    end

    def call
      tournament_round.matches.where.not(status: :finished).where.not(page_url: [nil, '']).find_each do |match|
        Scores::Injectors::FotmobMatch.call(match, run_mode: :schedule, budget: budget)
      rescue StandardError => e
        Rollbar.error(e, match_id: match.id, page_url: match.page_url, tournament_round_id: tournament_round.id)
        Rails.logger.error("[live-scores] schedule refresh crashed for #{match.page_url}: #{e.class}: #{e.message}")
      end

      tournament_round.update(schedule_refreshed_at: Time.current)
    end

    private

    attr_reader :tournament_round, :budget
  end
end
