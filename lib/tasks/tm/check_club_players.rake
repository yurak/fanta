# rubocop:disable Metrics/BlockLength:
namespace :tm do
  # rake 'tm:check_club_players_csv[1]'
  desc 'Check TM players list from club pages and write to csv'
  task :check_club_players_csv, %i[tournament_id] => :environment do |_t, args|
    clubs = if args[:tournament_id] == '8' || args[:tournament_id] == '20'
              Club.active.where(tournament_id: nil, ec_tournament_id: args[:tournament_id]).order(:name)
            elsif args[:tournament_id]
              Club.active.where(tournament_id: args[:tournament_id]).order(:name)
            else
              Club.active.order(:name)
            end
    # clubs = Club.archived.order(:name)

    CSV.open('log/club_players.csv', 'ab') do |writer|
      writer << ["--------#{DateTime.now.strftime('%b %e, %H:%M')}--------"]
      Players::Transfermarkt::ClubPlayersScraper.call(clubs: clubs, writer: writer)
    end
  end

  # rake 'tm:check_club_players[1]'
  desc 'Check TM players list from club pages and print tm_id'
  task :check_club_players, %i[tournament_id] => :environment do |_t, args|
    clubs = args[:tournament_id] ? Club.active.where(tournament_id: args[:tournament_id]).order(:name) : Club.active.order(:name)

    clubs.each do |club|
      puts "--------#{club.name}--------"
      response = RestClient::Request.execute(method: :get, url: club.tm_url, headers: { 'User-Agent': 'product/version' },
                                             verify_ssl: false)
      html_page = Nokogiri::HTML(response)
      players = html_page.css('.inline-table .hauptlink')

      players.each do |player_data|
        tm_id = player_data.children.first.attributes['href'].value.split('/').last
        player = Player.find_by(tm_id: tm_id)
        puts tm_id unless player
      end

      sleep(10)
    end
  end
end
# rubocop:enable Metrics/BlockLength
