namespace :tm do
  # rake 'tm:parse_create_player[1000000]'
  desc 'Parse player data from TM, create player and write data to csv'
  task :parse_create_player, %i[player_tm_id] => :environment do |_t, args|
    tm_id = args[:player_tm_id]
    next unless args[:player_tm_id]

    player = Player.find_by(tm_id: tm_id)
    puts "Player #{tm_id} already exist - #{player.id} #{player.full_name}" if player
    next if player

    CSV.open('log/players_new_by_tm_id.csv', 'ab') do |writer|
      result = Players::Transfermarkt::ApiParser.call(tm_id)
      next unless result

      player = Players::Manager.call(result.stringify_keys)
      if player
        writer << ['', result[:first_name], result[:name], result[:nationality], result[:club_name],
                   result[:position1], result[:position2], result[:position3], result[:tm_url], '',
                   result[:tm_pos1], result[:tm_pos2], result[:tm_pos3]]
        puts "Player #{tm_id} created!"
      else
        puts "Player #{tm_id} haven't been created - #{result}"
      end
    end
  end
end
