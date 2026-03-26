# frozen_string_literal: true

module Results
  class TotalScoreUpdater < ApplicationService
    def initialize(league)
      @league = league
    end

    def call
      league.teams.each do |team|
        season_total = team.lineups.by_league(league.id).sum(&:total_score)
        team.results.last&.update!(total_score: season_total)
      end
    end

    private

    attr_reader :league
  end
end
