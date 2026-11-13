namespace :tm do
  # rake 'tm:inject_player_data[1,14999]'
  # Refreshes TM data (value, number, birth date, height, nationality) for players in the id range.
  #
  # PRICE_ONLY=1 narrows it to tm_price, TM_SLEEP sets the pause between requests (default 30s)
  # and TM_SKIP_CACHE=1 bypasses the week-long cache.
  desc 'Inject TM data'
  task :inject_player_data, %i[start_id last_id] => :environment do |_t, args|
    start_id = args[:start_id].to_i
    last_id = args[:last_id].to_i
    price_only = ENV['PRICE_ONLY'].present?
    pause = ENV.fetch('TM_SLEEP', 30).to_i
    fields = price_only ? [:tm_price] : Players::Transfermarkt::ProfileUpdater::FIELDS

    players = Player.where.not(tm_id: nil).where(id: start_id..last_id).order(:id)

    total = 0
    updated = 0
    cached = 0
    blocked = nil

    players.find_each do |player|
      total += 1
      from_cache = Players::Transfermarkt::CacheProbe.fresh?(player.tm_id)
      cached += 1 if from_cache

      changes = Players::Transfermarkt::ProfileUpdater.call(player, only: fields)
      updated += 1 if changes.any?

      note = changes.map { |field, (was, now)| "#{field} #{was} -> #{now}" }.join(', ')
      line = "#{player.id} / #{player.name}"
      line += ' [cache]' if from_cache
      line += ": #{note}" if note.present?
      puts line

      sleep(pause) unless from_cache || pause.zero?
    rescue Players::Transfermarkt::ApiError => e
      if e.blocked? || e.is_a?(Players::Transfermarkt::ApiUnavailableError)
        blocked = "player #{player.id} / #{player.tm_id}: #{e.message}"
        break
      end

      puts "Error for player #{player.id} / #{player.tm_id}: #{e.message}"
    rescue StandardError => e
      puts "Error for player #{player.id} / #{player.tm_id}: #{e.message}"
    end

    if blocked
      puts "\nSTOPPED: Transfermarkt refused the request — #{blocked}"
      puts 'Nothing more was requested. Wait for the block to lift before re-running.'
    end

    puts "Done. Players: #{total}, updated: #{updated}, served from cache: #{cached}"
  end
end
