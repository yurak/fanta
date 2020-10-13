namespace :leagues do
  desc 'Create League with Users and Teams'
  task create_with_teams: :environment do
    leagues_data = YAML.load_file(Rails.root.join('config', 'mantra', 'users.yml'))
    leagues_data.each do |league_name, league_data|
      puts "Creating league: #{league_name}"
      tournament = Tournament.find_by(code: league_data['tournament'])
      league = League.create(name: league_name, tournament: tournament, status: 0, season: Season.last)
      next unless league

      league_data['members'].each do |team_name, user_email|
        user = User.find_by(email: user_email)
        if user
          team = user.teams.find_by(name: team_name)
        else
          user = User.create(email: user_email, password: '123456')
        end

        if team
          team.update(league: league)
        else
          Team.create(name: team_name, user: user, league: league, human_name: team_name.titleize[0..18])
        end
      end
    end
    puts 'Done!'
  end
end
