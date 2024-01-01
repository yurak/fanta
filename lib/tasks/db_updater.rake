namespace :db_updater do
  desc 'Update DB to add leagues and tournaments'
  task add_league_and_tournaments: :environment do
    # create tournaments
    Tournaments::Creator.call
    tournament = Tournament.find_by(code: Scores::Injectors::Strategy::ITALY)

    # add created tournament to existed clubs
    Club.find_each { |c| c.update(tournament: tournament) }

    # create clubs
    Clubs::Creator.call

    # create league (with tournament) for existed data
    league = League.create(name: 'Fanta-2019/2020', tournament: tournament, status: 1)

    # add created league to existed teams
    Team.find_each { |t| t.update(league: league) }

    # add created league to existed tours
    Tour.find_each { |t| t.update(league: league) }

    # add created league to existed links
    Link.find_each { |l| l.update(league: league) }
  end
end
