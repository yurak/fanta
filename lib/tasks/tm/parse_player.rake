namespace :tm do
  # rake 'tm:parse_player[123456]'
  desc 'Parse player data from TM'
  task :parse_player, %i[player_tm_id] => :environment do |_t, args|
    tm_id = args[:player_tm_id]
    next unless args[:player_tm_id]

    player = Player.find_by(tm_id: tm_id)
    puts "Player #{tm_id} already exist - #{player.id} #{player.full_name}" if player
    next if player

    CSV.open('log/players_new_by_tm_id.csv', 'ab') do |writer|
      result = Players::Transfermarkt::ApiParser.call(tm_id)
      puts result.stringify_keys

      writer << ['', result[:first_name], result[:name], result[:nationality], result[:club_name],
                 result[:position1], result[:position2], result[:position3], result[:tm_url], '',
                 result[:tm_pos1], result[:tm_pos2], result[:tm_pos3], '', '',
                 result[:tm_price], result[:number], result[:birth_date], result[:height]]
    end
  end

  # rake 'tm:parse_players_range[1,19999]'
  desc 'Parse players data from TM'
  task :parse_players_range, %i[start_id last_id] => :environment do |_t, args|
    ids_range = args[:start_id].to_i..args[:last_id].to_i

    CSV.open('log/player_data_updates.csv', 'ab') do |writer|
      writer << %w[id first_name name nationality tm_price number birth_date height tm_club club tm_url]
      ids_range.each do |id|
        player = Player.find_by(id: id)
        next unless player&.tm_id

        puts id
        result = Players::Transfermarkt::ApiParser.call(player.tm_id, position_skip: true)

        writer << [id, result[:first_name], result[:name], result[:nationality],
                   result[:tm_price], result[:number], result[:birth_date], result[:height],
                   result[:tm_club_name], player.club.tm_name, result[:tm_url]]
        sleep(5)
      end
    end
  end

  # rake 'tm:parse_player_by_id_list'
  desc 'Parse player data from TM by ids from csv'
  task parse_player_by_id_list: :environment do
    CSV.foreach('log/players_data.csv', headers: true) do |row|
      tm_id = row['id']
      puts tm_id

      player = Player.find_by(tm_id: tm_id)
      puts "Player #{tm_id} already exist - #{player.id} #{player.full_name}" if player
      next if player

      CSV.open('log/players_new_by_tm_id.csv', 'ab') do |writer|
        result = Players::Transfermarkt::ApiParser.call(tm_id)
        output = result.stringify_keys
        output['national_team'] = row['national_team'] if row['national_team'].present?
        puts output

        writer << ['', result[:first_name], result[:name], result[:nationality], result[:club_name],
                   result[:position1], result[:position2], result[:position3], result[:tm_url], row['national_team'],
                   result[:tm_pos1], result[:tm_pos2], result[:tm_pos3], '', '',
                   result[:tm_price], result[:number], result[:birth_date], result[:height]]
      end
      sleep(5)
    end
  end
end
