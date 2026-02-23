namespace :players do
  # rake 'players:run_csv_parser[file_name]'
  desc 'Update and create players from csv file'
  task :run_csv_parser, %i[file_name] => :environment do |_t, args|
    Players::CsvParser.call(nil, args[:file_name])
  end

  # rake 'players:run_csv_parser_url[file_url]'
  desc 'Update and create players from external csv file by url'
  task :run_csv_parser_url, %i[file_url] => :environment do |_t, args|
    Players::CsvParser.call(args[:file_url])
  end
end
