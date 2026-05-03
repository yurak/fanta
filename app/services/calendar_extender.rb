class CalendarExtender < ApplicationService
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

  def create_tour(tour_number, round_number, tour_games)
    tour = Tour.create(number: tour_number, league: league, tournament_round: t_round(tour_number))
    tour_games.each do |team_ids|
      team_ids = team_ids.reverse if round_number.odd?
      Match.create(tour: tour, host_id: team_ids[0], guest_id: team_ids[1])
    end
  end

  def round_games
    teams_array.push nil if teams_array.size.odd?
    n = teams_array.size
    pivot = teams_array.pop
    games = tour_games(n, pivot)

    (n - 1).times.map do |tour|
      next if tour.even?

      games[tour] = [[teams_array.first, pivot]] + (1...(n / 2)).map { |j| [teams_array[j], teams_array[n - 1 - j]] }
      teams_array.rotate!
    end
    teams_array.push pivot unless pivot.nil?
    games
  end

  def tour_games(count, pivot)
    (count - 1).times.map do |tour|
      next if tour.odd?

      tour_games = [[pivot, teams_array.first]] + (1...(count / 2)).map { |j| [teams_array[j], teams_array[count - 1 - j]] }
      teams_array.rotate!
      tour_games
    end
  end

  def rounds
    @rounds ||= additional_tours? ? (full_rounds + 1) : full_rounds
  end

  def full_rounds
    @total_tours / round_tours
  end

  def round_tours
    teams_array.count - 1
  end

  def additional_tours?
    (@total_tours % round_tours).positive?
  end

  def teams_array
    @teams_array ||= league.teams.ids
  end

  def league
    return @league if defined?(@league)

    @league = League.find_by(id: @league_id)
  end

  def tournament
    @tournament ||= league.tournament
  end

  def season
    @season ||= league.season
  end

  def t_round(tour_number)
    round_number = tour_number + league.tour_difference
    TournamentRound.find_by(tournament: tournament, number: round_number, season: season)
  end
end
