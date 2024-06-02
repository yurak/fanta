namespace :player_season_stats do
  # rake 'player_season_stats:generate'
  desc 'Generate player total stats after season'
  task generate: :environment do
    Stats::Creator.call
  end

  # rake 'player_season_stats:update_price'
  desc 'Update player default price after season'
  task update_price: :environment do
    # TODO: update price with updated positions
    Tournament.with_clubs.each do |tournament|
      Stats::PriceUpdater.call(tournament)
    end
  end
end
