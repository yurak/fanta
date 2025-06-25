namespace :tm do
  # rake 'tm:inject_player_data[1,14999]'
  desc 'Inject TM data'
  task :inject_player_data, %i[start_id last_id] => :environment do |_t, args|
    ids_range = args[:start_id].to_i..args[:last_id].to_i
    max_attempts = 5
    ids_range.to_a.each do |id|
      player = Player.find_by(id: id)
      next unless player

      p "Inject player data: #{player.name} (id: #{player.id})"
      attempt = 0
      begin
        attempt += 1
        Players::Transfermarkt::BaseUpdater.call(player)
      rescue RestClient::Exception => e
        if attempt <= max_attempts
          puts "Retry ##{attempt} - #{player.id}"
          sleep(120)
          retry
        else
          puts "error for id #{player.id} - #{e}"
        end
      end

      if (id % 2).zero? ? sleep(90) : sleep(30)
    end
  end
end
