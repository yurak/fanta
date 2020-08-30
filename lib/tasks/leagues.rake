namespace :leagues do
  desc 'Create League with Users and Teams'
  task create_with_teams: :environment do
    leagues_data = YAML.load_file(Rails.root.join('config', 'mantra', 'users.yml'))
    leagues_data.each do |league_name, league_data|
      puts "Creating league: #{league_name}"
      tournament = Tournament.find_by(code: league_data['tournament'])
      league = League.create(name: league_name, tournament: tournament, status: 0, season: Season.last)
      next unless league

      league_data['members'].each do |team, user_email|
        user = User.create(email: user_email, password: '123456')
        Team.create(name: team, user: user, league: league)
      end
    end
    puts 'Done!'
  end
end
