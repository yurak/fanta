namespace :db_updater do
  desc 'Update DB to add leagues and tournaments'
  task add_league_and_tournaments: :environment do
    # create tournaments
    TournamentCreator.call

    # create league (with tournament) for existed data
    league = League.create(name: 'Fanta-2019/2020', tournament: Tournament.find_by(code: 'serie_a'), status: 1)

    # add created league to existed teams
    Team.all.each { |t| t.update(league: league) }

    # add created league to existed tours
    Tour.all.each { |t| t.update(league: league) }

    # add created league to existed links
    Link.all.each { |l| l.update(league: league) }
  end
end
