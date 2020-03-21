namespace :players do
  desc 'Update and create players from csv file'
  task :run_csv_parser, %i[file_name] => :environment do |_t, args|
    file_name = args[:file_name]
    Players::CsvParser.call(file_name)
  end
end
