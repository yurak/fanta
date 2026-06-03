class CalendarExtender < ApplicationService
  include CalendarBuilder

  def initialize(league_id, extra_tours)
    @league_id = league_id
    @extra_tours = extra_tours.to_i
  end

  def call
    return false unless league
    return false if teams_array.size < CalendarCreator::MIN_TEAMS

    @start_tour = league.tours.maximum(:number).to_i + 1
    @total_tours = @start_tour + @extra_tours - 1

    return false unless t_round(@start_tour)

    tour_number = 1
    rounds.times do |round_number|
      round_games.each do |tour_games|
        break if tour_number > @total_tours

        create_tour(tour_number, round_number, tour_games) if tour_number >= @start_tour
        tour_number += 1
      end
    end
  end

  private

  def max_tours
    @total_tours
  end

  def create_tour(tour_number, round_number, tour_games)
    tour = Tour.create(number: tour_number, league: league, tournament_round: t_round(tour_number))
    tour_games.each do |team_ids|
      team_ids = team_ids.reverse if round_number.odd?
      Match.create(tour: tour, host_id: team_ids[0], guest_id: team_ids[1])
    end
  end
end
