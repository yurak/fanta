class CreateTournamentRounds < ActiveRecord::Migration[5.2]
  def change
    create_table :tournament_rounds do |t|
      t.references :tournament, foreign_key: true
      t.references :season, foreign_key: true
      t.integer :number
      t.integer :status, default: 0
      t.datetime :start_time

      t.timestamps
    end

    add_reference :tours, :tournament_round, foreign_key: true

    season = Season.first
    Tournament.joins(:leagues).uniq.each do |t|
      start_tour_number = t.leagues.first.tour_difference + 1
      (start_tour_number..38).each do |round_number|
        TournamentRound.create(tournament: t, season: season, number: round_number)
      end
    end
    Tour.all.each do |tour|
      round_number = tour.number + tour.league.tour_difference
      tournament_round = TournamentRound.find_by(tournament: tour.league.tournament, number: round_number)
      tour.update(tournament_round_id: tournament_round.id)
    end
  end
end
