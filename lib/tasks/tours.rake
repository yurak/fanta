namespace :tours do
  desc 'Unlock tour by number'
  task :unlock, [:number] => :environment do |_t, args|
    tour = Tour.find_by(number: args[:number].to_i)
    tour&.set_lineup!
  end

  desc 'Create tours for Euro'
  task create_euro: :environment do
    tournament = Tournament.find_by(code: Scores::Injectors::Strategy::EURO)
    league = tournament.leagues.last
    tournament.tournament_rounds.each do |round|
      first_match = round.national_matches.first
      deadline = DateTime.parse("#{first_match.date} #{first_match.time}") - 90.minutes
      Tour.create(tournament_round: round, league: league, number: round.number, deadline: deadline)
    end
  end
end
