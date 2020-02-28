namespace :winter_auction do
  task exchanges: :environment do
    exchanges_map = YAML.load_file(Rails.root.join('config', 'auctions', 'exchanges.yml'))['exchanges']

    exchanges_map.each do |exchange|
      from_team = Team.find_by(name: exchange.dig('from', 'name'))
      to_team = Team.find_by(name: exchange.dig('to', 'name'))
      next unless from_team && to_team

      from_players = from_team.players.where(name: exchange.dig('from', 'players'))
      to_players = to_team.players.where(name: exchange.dig('to', 'players'))
      next unless from_players && to_players

      Player.transaction do
        from_players.update_all(team_id: to_team.id)
        to_players.update_all(team_id: from_team.id)
      end
    end
    puts 'Finish'
  end

  task remove_player_from_the_team: :environment do
    teams = YAML.load_file(Rails.root.join('config', 'auctions', 'free_agents.yml'))['free_agents']
    teams.each do |team_name, players|
      team = Team.find_by(name: team_name)
      next unless team && players

      players.each do |player_name|
        player = team.players.find_by(name: player_name)
        next unless player

        player.team_id = nil
        player.save validate: false
        puts "Club #{team.name.titleize} terminated contract with #{player.name}"
      end
    end
    puts 'Finish'
  end

  task club_transfers: :environment do
    transfers = YAML.load_file(Rails.root.join('config', 'auctions', 'club_transfers.yml'))['club_transfers']
    transfers.each do |player_name, clubs|
      from_club = Club.find_by(code: clubs['from'])
      player = from_club.players.find_by(name: player_name)
      if player
        to_club = Club.find_by(code: clubs['to'])
        player.update(club_id: to_club.id)
        puts "Player #{player_name} is moved from club #{clubs['from']} to #{clubs['to']}"
      else
        puts "Player #{player_name} from club #{clubs['from']} cannot be found, transfer skipped"
      end
    end
    puts 'Finish'
  end
end
