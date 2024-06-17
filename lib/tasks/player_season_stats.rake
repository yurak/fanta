namespace :player_season_stats do
  # rake 'player_season_stats:generate'
  desc 'Generate player total stats after season'
  task generate: :environment do
    Stats::Creator.call
  end

  # rake 'player_season_stats:update_price[tournament_id]'
  desc 'Update player default price after season by tournament id'
  task :update_price, %i[tournament_id] => :environment do |_t, args|
    tournament = Tournament.find(args[:tournament_id])
    next unless tournament

    Stats::PriceUpdater.call(tournament)
  end
end
