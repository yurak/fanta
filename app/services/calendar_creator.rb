class CalendarCreator < ApplicationService
  include CalendarBuilder

  MIN_TEAMS = 2

  def initialize(league_id, max_tours)
    @league_id = league_id
    @max_tours = max_tours.to_i
  end

  def call
    return false unless league
    return false if teams_array.size < MIN_TEAMS

    @tour_number = 1
    return false unless t_round(@tour_number)

    rounds.times { |round_number| create_round_tours(round_number) }
  end

  private

  attr_reader :max_tours

  def create_round_tours(round_number)
    round_games.each do |tour_games|
      break if @tour_number > @max_tours

      create_tour_matches(round_number, tour_games)
      @tour_number += 1
    end
  end

  def create_tour_matches(round_number, tour_games)
    tour = Tour.create(number: @tour_number, league: league, tournament_round: t_round(@tour_number))
    tour_games.each do |team_ids|
      team_ids = team_ids.reverse if round_number.odd?
      Match.create(tour: tour, host_id: team_ids[0], guest_id: team_ids[1])
    end
  end
end
