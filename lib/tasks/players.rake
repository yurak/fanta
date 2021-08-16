namespace :players do
  desc 'Update and create players from csv file'
  task :run_csv_parser, %i[file_name] => :environment do |_t, args|
    Players::CsvParser.call(file_name: args[:file_name])
  end

  desc 'Update and create players from external csv file by url'
  task :run_csv_parser_url, %i[file_url] => :environment do |_t, args|
    Players::CsvParser.call(file_url: args[:file_url])
  end

  desc 'Inject TM data'
  task :inject_tm_data, %i[start_id last_id] => :environment do |_t, args|
    ids_range = args[:start_id].to_i..args[:last_id].to_i
    ids_range.to_a.each do |id|
      player = Player.find_by(id: id)
      next unless player

      p "Inject player data: #{player.name} (id: #{player.id})"
      Players::TmParser.call(player)
    end
  end
end
