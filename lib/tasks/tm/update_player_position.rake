# rubocop:disable Metrics/BlockLength:
namespace :tm do
  # rake 'tm:update_player_position[1,15000]'
  desc 'Update player positions by TM data'
  task :update_player_position, %i[start_id last_id] => :environment do |_t, args|
    ids_range = args[:start_id].to_i..args[:last_id].to_i

    CSV.open('log/update_player_position.csv', 'ab') do |writer|
      writer << ['time', 'id', 'name', 'club', 'tm_url', 'actual positions', 'recommended positions']

      ids_range.to_a.each do |id|
        writer << ["id #{id} processing #{Time.zone.now}"] if (id % 50).zero?
        player = Player.find_by(id: id)
        next unless player&.tm_id
        next if player.club.name == Club::RETIRED
        next if player.club.tournament_id == 16 # skip MLS players
        next if player.club.tournament_id == 19 # skip Brazil players

        # next unless player.club.tournament_id == 16 # only MLS players
        # next unless player.club.tournament_id == 19 # only Brazil players

        begin
          pos = player.player_positions.map { |pp| Slot::POS_MAPPING[pp.position.name] }
          log = [Time.zone.now, player.id, player.name, player.club.name, player.tm_url, pos.join(',')]
          result = PlayerPositions::Updater.call(player)

          log << result.join(',') if result
          writer << log unless result && pos.sort == result
        rescue RestClient::Exception => e
          writer << ["#{Time.zone.now} // error for id #{player.id} / #{player.tm_id} - #{e}"]
        end
      end
    end
  end

  # rake 'tm:update_player_position_url[url]'
  desc 'Update player positions by TM data from csv url'
  task :update_player_position_url, %i[url] => :environment do |_t, args|
    csv = CSV.parse(URI.parse(args[:url]).open.read, headers: true)

    csv.each do |player_data|
      player = Player.find_by(id: player_data['id'])
      next unless player

      positions = player_data['new positions'].split(',')
      puts "#{player.id} - #{player_data['new positions']}"

      PlayerPositions::Updater.call(player, positions)
    end
  end
end
# rubocop:enable Metrics/BlockLength
