namespace :tm do
  # rake 'tm:update_player_position[1,15000]'
  desc 'Update player positions by TM data'
  task :update_player_position, %i[start_id last_id] => :environment do |_t, args|
    ids_range = args[:start_id].to_i..args[:last_id].to_i

    CSV.open('log/update_player_position.csv', 'ab') do |writer|
      writer << ['id', 'name', 'club', 'tm_url', 'actual positions', 'recommended positions']

      ids_range.to_a.each do |id|
        player = Player.find_by(id: id)
        next unless player&.tm_id

        begin
          pos = player.player_positions.map { |pp| Slot::POS_MAPPING[pp.position.name] }
          log = [player.id, player.name, player.club.name, player.tm_url, pos.join(',')]
          result = PlayerPositions::Updater.call(player)

          log << result.join(',') if result
          writer << log unless result && pos.sort == result
        rescue RestClient::Exception => e
          writer << "error for id #{player.id} / #{player.tm_id} - #{e}"
        end
      end
    end
  end
end
