namespace :t_rounds do
  # rake 't_rounds:create[15,5,30]'
  desc 'Create TournamentRounds by tournament_id and season_id'
  task :create, %i[tournament_id season_id rounds_count] => :environment do |_t, args|
    count = args[:rounds_count] ? args[:rounds_count].to_i : 38
    TournamentRounds::Creator.call(args[:tournament_id], args[:season_id], count)
    puts 'Done!'
  end
end
