module Tours
  class ScheduleRefresher < ApplicationService
    def initialize(tournament_round)
      @tournament_round = tournament_round
    end

    def call
      round_matches.where.not(page_url: [nil, '']).find_each do |match|
        Scores::Injectors::FotmobMatch.call(match, run_mode: :schedule)
      end

      tournament_round.update(schedule_refreshed_at: Time.current)
    end

    private

    attr_reader :tournament_round

    def round_matches
      tournament_round.tournament.national? ? tournament_round.national_matches : tournament_round.tournament_matches
    end
  end
end
