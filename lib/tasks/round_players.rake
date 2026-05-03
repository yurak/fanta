namespace :round_players do
  # rake 'round_players:create[1208]'
  desc 'Create RoundPlayers by tournament_round_id'
  task :create, %i[tournament_round_id] => :environment do |_t, args|
    RoundPlayers::Creator.call(args[:tournament_round_id])
    puts 'Done!'
  end

  # rake 'round_players:inject[1208]'
  desc 'Inject RoundPlayers scores by tournament_round_id'
  task :inject, %i[tournament_round_id] => :environment do |_t, args|
    tournament_round = TournamentRound.find_by(id: args[:tournament_round_id])
    if tournament_round
      Scores::Injectors::Fotmob.call(tournament_round)
      puts 'Done!'
    else
      puts 'Incorrect TournamentRound id'
    end
  end
end
