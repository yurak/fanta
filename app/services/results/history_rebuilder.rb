module Results
  class HistoryRebuilder < ApplicationService
    attr_reader :league

    def initialize(league)
      @league = league
    end

    def call
      return false unless league

      Results::Creator.call(league.id)
      reset_results
      closed_tours.each { |tour| updater.call(tour) }
      true
    end

    private

    def reset_results
      Result.where(league_id: league.id).find_each(&:reset_stats)
    end

    def closed_tours
      Tour.where(league_id: league.id, status: :closed).order(:number)
    end

    def updater
      league.fanta? ? Results::FantaUpdater : Results::Updater
    end
  end
end
