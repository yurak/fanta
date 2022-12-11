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

      update_history
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
      result = results.by_team(winner.id).last
      result.update(
        points: result.points + 3,
        wins: result.wins + 1,
        scored_goals: result.scored_goals + match.scored_goals(winner),
        missed_goals: result.missed_goals + match.missed_goals(winner),
        total_score: result.total_score + winner_lineup.total_score.round(2)
      )
    end

    def update_loser(match, loser, loser_lineup)
      result = results.by_team(loser.id).last
      result.update(
        loses: result.loses + 1,
        scored_goals: result.scored_goals + match.scored_goals(loser),
        missed_goals: result.missed_goals + match.missed_goals(loser),
        total_score: result.total_score + loser_lineup.total_score.round(2)
      )
    end

    def update_result_draw(match, team, lineup)
      result = results.by_team(team.id).last
      result.update(
        points: result.points + 1,
        draws: result.draws + 1,
        scored_goals: result.scored_goals + match.scored_goals(team),
        missed_goals: result.missed_goals + match.missed_goals(team),
        total_score: result.total_score + lineup.total_score.round(2)
      )
    end

    def update_history
      results.each do |result|
        history_arr = result.history_arr
        # position:, points:, scored_goals:, missed_goals:, wins:, draws:, loses:, total_score:
        history_arr[tour.number] = { pos: result.position, p: result.points, sg: result.scored_goals, mg: result.missed_goals,
                                     w: result.wins, d: result.draws, l: result.loses, ts: result.total_score }
        result.update(history: history_arr.to_json)
      end
    end

    def results
      @results ||= league.results
    end

    def league
      @league ||= tour.league
    end
  end
end
