namespace :club_transfers do
  # rake 'club_transfers:import_history[1,20000]'
  # Fetches the full TM transfer history for players in the id range,
  # upserts it into club_transfers (idempotent by tm_transfer_id) and then, for each
  # player, creates a pending ClubTransferRequest when the latest transfer's club
  # differs from the player's current Mantra club. Use TM_SKIP_CACHE=1 to bypass cache.
  desc 'Import TM transfer history and build pending club-transfer requests for players in id range'
  task :import_history, %i[from_id to_id] => :environment do |_t, args|
    from_id = args[:from_id]&.to_i
    to_id   = args[:to_id]&.to_i

    players = Player.where.not(tm_id: nil).order(:id)
    players = players.where('players.id >= ?', from_id) if from_id&.positive?
    players = players.where('players.id <= ?', to_id)   if to_id&.positive?

    total_players = 0
    total_imported = 0
    total_requests = 0

    players.find_each do |player|
      total_players += 1
      imported = ClubTransfers::HistoryImporter.call(player)
      total_imported += imported
      request = ClubTransfers::RequestBuilder.call(player)
      total_requests += 1 if request
      puts "#{player.id} / #{player.name}: #{imported} transfers#{' + request' if request}"
    rescue StandardError => e
      puts "Error for player #{player.id} / #{player.tm_id}: #{e.message}"
    end

    puts "Done. Players: #{total_players}, transfers imported: #{total_imported}, requests: #{total_requests}"
  end
end
