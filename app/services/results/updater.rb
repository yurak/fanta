module Results
  class Updater < ApplicationService
    attr_reader :tour

    def initialize(tour)
      @tour = tour
    end

    def call
      return false unless tour&.matches.present? && tour.locked?

      tour.matches.each do |match|
        if match.host_win?
          update_result_win(match, match.host, match.guest)
        elsif match.guest_win?
          update_result_win(match, match.guest, match.host)
        elsif match.draw?
          update_result_draw(match, match.host)
          update_result_draw(match, match.guest)
        end
      end
    end

    private

    def update_result_win(match, winner, loser)
      winner.results.last.update(
        points: winner.results.last.points + 3,
        wins: winner.results.last.wins + 1,
        scored_goals: winner.results.last.scored_goals + match.scored_goals(winner),
        missed_goals: winner.results.last.missed_goals + match.missed_goals(winner)
      )
      loser.results.last.update(
        loses: loser.results.last.loses + 1,
        scored_goals: loser.results.last.scored_goals + match.scored_goals(loser),
        missed_goals: loser.results.last.missed_goals + match.missed_goals(loser)
      )
    end

    def update_result_draw(match, team)
      team.results.last.update(
        points: team.results.last.points + 1,
        draws: team.results.last.draws + 1,
        scored_goals: team.results.last.scored_goals + match.scored_goals(team),
        missed_goals: team.results.last.missed_goals + match.missed_goals(team)
      )
    end
  end
end
