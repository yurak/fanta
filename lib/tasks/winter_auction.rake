namespace :winter_auction do
  task :exchanges => :environment do
    player_map = YAML.load_file(Rails.root.join('config', 'auctions', 'exchanges.yml'))['exchanges']

    player_map.each do |player_name, team_name|
      team = Team.find_by(name: team_name)
      player = Player.find_by(name: player_name)
      if player.team_id != team.id
        player.team_id = team.id
        player.save validate: false
        puts "#{player_name} was moved to the team ---> #{team_name}"
      elsif player.team_id == team.id
        puts "#{player_name} is already in the team ---> #{team_name}"
      else
        puts 'Cant move to the team'
      end
    end

    puts 'Finish'
  end

  task :remove_player_from_the_team => :environment do
    player_names = YAML.load_file(Rails.root.join('config', 'auctions', 'free_agents.yml'))['free_agents']
    player_names.each do |player_name|
      player = Player.find_by(name: player_name)

      if player && player.team
        player_team_was = player.team
        player.team_id = nil

        player.save validate: false
      end
    end
    puts 'Finish'
  end
end
