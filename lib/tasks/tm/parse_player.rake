# rubocop:disable Metrics/BlockLength:
namespace :tm do
  # rake 'tm:parse_player[1458907]'
  desc 'Parse player data from TM'
  task :parse_player, %i[player_tm_id] => :environment do |_t, args|
    tm_id = args[:player_tm_id]
    next unless args[:player_tm_id]

    player = Player.find_by(tm_id: tm_id)
    puts "Player #{tm_id} already exist - #{player.id} #{player.full_name}" if player
    next if player

    CSV.open('log/players_new_by_tm_id.csv', 'ab') do |writer|
      result = Players::Transfermarkt::Parser.call(tm_id)
      puts result.stringify_keys

      writer << ['', result[:first_name], result[:name], result[:nationality], result[:club_name],
                 result[:position1], result[:position2], result[:position3], result[:tm_url], '',
                 result[:tm_pos1], result[:tm_pos2], result[:tm_pos3]]
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
        result = Players::Transfermarkt::Parser.call(tm_id)
        puts row['national_team']
        puts result.stringify_keys

        writer << ['', result[:first_name], result[:name], result[:nationality], result[:club_name],
                   result[:position1], result[:position2], result[:position3], result[:tm_url], row['national_team'],
                   result[:tm_pos1], result[:tm_pos2], result[:tm_pos3]]
      end
      sleep(20)
    end
  end
end
# rubocop:enable Metrics/BlockLength
