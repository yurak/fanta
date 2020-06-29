namespace :results_generator do
  desc 'Generate random lineups and scores'
  task generate_tour_results: :environment do
    puts 'Rake is deprecated'
    # active_tour = Tour.active
    # unless active_tour
    #   active_tour = Tour.inactive.first
    #   TourManager.new(tour: active_tour, status: 'set_lineup').call
    # end
    #
    # Team.all.each do |team|
    #   l = Lineup.create(tour_id: active_tour.id, team_id: team.id, team_module_id: rand(1..11))
    #   l.slots.each do |slot|
    #     player = team.players.includes(:positions).where(positions: { name: slot.position }).first || team.players.last
    #     MatchPlayer.create(lineup_id: l.id, player_id: player.id, score: rand(4.00..9.99), real_position: slot.position)
    #   end
    #   7.times do
    #     MatchPlayer.create(lineup_id: l.id, player_id: team.players[rand(1..24)].id)
    #   end
    # end
    # TourManager.new(tour: active_tour, status: 'locked').call
    # TourManager.new(tour: active_tour, status: 'closed').call
  end
end
