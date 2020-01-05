namespace :winter_auction do
  task :change_players_club, [:club_new, :player_name] => :environment do |task, args|
    player = Player.find_by(name: args[:player_name])

    club_new = Club.find_by(code: args[:club_new])
    if club_new && player
      player.club_id = club_new.id

      player.save validate: false
      puts "player club was changed to ---> #{club_new.name}"
    else
      puts "check psrameretes"
    end
    puts 'Finish'
  end

  task :remove_player_from_the_team, [:player_name] => :environment do |task, args|
    player = Player.find_by(name: args[:player_name])

    unless player
      puts 'wrong player_name'
      break
    end

    unless player.team
       puts 'player has no team'
      break
    end

    if player && player.team
      player_team_was = player.team
      player.team_id = nil

      player.save validate: false
      puts "player eas removed from the team ---> #{player_team_was.name}"
    end
    puts 'Finish'
  end
end
