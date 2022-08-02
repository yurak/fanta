module Results
  class Updater < ApplicationService
    attr_reader :tour

    def initialize(tour)
      @tour = tour
    end

    def call
      return false unless tour&.matches.present? && tour.closed?

      tour.matches.each do |match|
        update_results(match)
      end
    end

    private

    def update_results(match)
      if match.host_win?
        update_result_win(match, match.host, match.guest, match.host_lineup, match.guest_lineup)
      elsif match.guest_win?
        update_result_win(match, match.guest, match.host, match.guest_lineup, match.host_lineup)
      elsif match.draw?
        update_result_draw(match, match.host, match.host_lineup)
        update_result_draw(match, match.guest, match.guest_lineup)
      end
    end

    def update_result_win(match, winner, loser, winner_lineup, loser_lineup)
      update_winner(match, winner, winner_lineup)

      update_loser(match, loser, loser_lineup)
    end

    def update_winner(match, winner, winner_lineup)
      winner.results.last.update(
        points: winner.results.last.points + 3,
        wins: winner.results.last.wins + 1,
        scored_goals: winner.results.last.scored_goals + match.scored_goals(winner),
        missed_goals: winner.results.last.missed_goals + match.missed_goals(winner),
        total_score: winner.results.last.total_score + winner_lineup.total_score.round(2)
      )
    end

    def update_loser(match, loser, loser_lineup)
      loser.results.last.update(
        loses: loser.results.last.loses + 1,
        scored_goals: loser.results.last.scored_goals + match.scored_goals(loser),
        missed_goals: loser.results.last.missed_goals + match.missed_goals(loser),
        total_score: loser.results.last.total_score + loser_lineup.total_score.round(2)
      )
    end

    def update_result_draw(match, team, lineup)
      team.results.last.update(
        points: team.results.last.points + 1,
        draws: team.results.last.draws + 1,
        scored_goals: team.results.last.scored_goals + match.scored_goals(team),
        missed_goals: team.results.last.missed_goals + match.missed_goals(team),
        total_score: team.results.last.total_score + lineup.total_score.round(2)
      )
    end
  end
end
