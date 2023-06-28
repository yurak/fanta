namespace :player_season_stats do
  desc 'player_season_stats:generate - Generate player total stats after season'
  task generate: :environment do
    Tournament.with_clubs.each do |tournament|
      Stats::Creator.call(tournament)
      Stats::PriceUpdater.call(tournament)
    end
  end
end
