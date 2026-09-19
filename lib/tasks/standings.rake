namespace :standings do
  # rake standings:refresh
  desc 'Refresh league tables from FotMob for every tournament that has a source id'
  task refresh: :environment do
    tournaments = Tournament.where.not(source_id: nil).order(:id)
    total = 0
    tournaments.each do |tournament|
      count = Standings::Updater.call(tournament)
      total += count
      puts "#{tournament.name}: #{count} rows"
    end
    puts "Done. Tournaments: #{tournaments.size}, rows: #{total}"
  end

  # rake standings:backfill_club_ids
  desc 'Fill clubs.fotmob_id from the FotMob ids of matches we already imported'
  task backfill_club_ids: :environment do
    Tournament.where.not(source_id: nil).order(:id).each do |tournament|
      puts "#{tournament.name}: #{Clubs::FotmobIdBackfiller.call(tournament)} clubs"
    end
  end
end
