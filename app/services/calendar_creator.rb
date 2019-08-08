class CalendarCreator
  MAX_TOURS = 38

  def call
    tour_number = 0
    rounds.times do |round_number|
      round_games.each do |tour_games|
        tour_number = tour_number + 1
        tour = Tour.create(number: tour_number)
        tour_games.each do |team_ids|
          team_ids = team_ids.reverse if round_number.odd?
          Match.create(tour: tour, host_id: team_ids[0], guest_id: team_ids[1])
        end
      end
    end
  end

  private

  def round_games
    teams_array.push nil if teams_array.size.odd?
    n = teams_array.size
    pivot = teams_array.pop
    games = (n-1).times.map do |tour|
      next if tour.odd?
      tour_games = [[pivot, teams_array.first]] + (1...(n / 2)).map { |j| [teams_array[j], teams_array[n - 1 - j]] }
      teams_array.rotate!
      tour_games
    end

    (n-1).times.map do |tour|
      next if tour.even?
      games[tour] = [[teams_array.first, pivot]] + (1...(n / 2)).map { |j| [teams_array[j], teams_array[n - 1 - j]] }
      teams_array.rotate!
    end
    teams_array.push pivot unless pivot.nil?
    games
  end

  def tours_count
    rounds * round_tours
  end

  def rounds
    MAX_TOURS / round_tours
  end

  def round_tours
    teams_array.count - 1
  end

  def teams_array
    # TODO: after League (Room) implementation - should be chosen teams from specific Room
    @teams_array ||= Team.all.ids
  end
end
