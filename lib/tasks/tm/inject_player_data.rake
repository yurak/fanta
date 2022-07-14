namespace :tm do
  desc 'Inject TM data'
  task :inject_player_data, %i[start_id last_id] => :environment do |_t, args|
    ids_range = args[:start_id].to_i..args[:last_id].to_i
    ids_range.to_a.each do |id|
      player = Player.find_by(id: id)
      next unless player

      p "Inject player data: #{player.name} (id: #{player.id})"
      Players::TmParser.call(player)
    end
  end
end
