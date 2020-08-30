namespace :t_rounds do
  desc 'Create TournamentRounds by tournament_id and season_id'
  task :create, %i[tournament_id season_id] => :environment do |_t, args|
    TournamentRounds::Creator.call(args[:tournament_id], args[:season_id])
    puts 'Done!'
  end
end
