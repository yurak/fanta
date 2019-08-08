class CalendarCreator
  MAX_TOURS = 38

  def call

    tour = 0
    round_games.each do |tour_games|
      tour = tour + 1
      # create Tour
      tour_games.each do |game|
        # game = game.reverse if round_by(tour)
        # create Match
      end
    end
  end

  private

  def round_games
    teams_array.push nil if teams_array.size.odd?
    n = teams_array.size
    pivot = teams_array.pop
    games = (n-1).times.map do |i|
      tour = i+1
      next if tour.even?
      tour_games = [[pivot, teams_array.first]] + (1...(n / 2)).map { |j| [teams_array[j], teams_array[n - 1 - j]] }
      teams_array.rotate!
      tour_games
    end

    (n-1).times.map do |i|
      tour = i+1
      next if tour.odd?
      games[i] = [[teams_array.first, pivot]] + (1...(n / 2)).map { |j| [teams_array[j], teams_array[n - 1 - j]] }
      teams_array.rotate!
    end
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
    # TODO: after League (Room) implementation - should be choosed teams from specific Room
    @teams_array ||= Team.all.ids
  end
end
