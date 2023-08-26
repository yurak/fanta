namespace :round_players do
  desc 'Create RoundPlayers by tournament_round_id'
  task :create, %i[tournament_round_id] => :environment do |_t, args|
    RoundPlayers::Creator.call(args[:tournament_round_id])
    puts 'Done!'
  end

  desc 'Inject RoundPlayers scores by tournament_round_id'
  task :calcio_inject, %i[tournament_round_id] => :environment do |_t, args|
    tournament_round = TournamentRound.find_by(id: args[:tournament_round_id])
    if tournament_round && tournament_round.tournament.code == Scores::Injectors::Strategy::ITALY
      Scores::Injectors::Calcio.call(tournament_round: tournament_round)
      puts 'Done!'
    else
      puts 'Incorrect TournamentRound id'
    end
  end
end
