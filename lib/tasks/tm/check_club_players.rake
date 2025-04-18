# rubocop:disable Metrics/BlockLength:
namespace :tm do
  # rake 'tm:check_club_players_csv[1]'
  desc 'Check TM players list from club pages and write to csv'
  task :check_club_players_csv, %i[tournament_id] => :environment do |_t, args|
    clubs = if args[:tournament_id] == '8'
              Club.active.where(tournament_id: nil, ec_tournament_id: args[:tournament_id]).order(:name)
            elsif args[:tournament_id]
              Club.active.where(tournament_id: args[:tournament_id]).order(:name)
            else
              Club.active.order(:name)
            end

    i = 0
    CSV.open('log/club_players.csv', 'ab') do |writer|
      clubs.each do |club|
        i += 1
        # next if i < 15
        # next if i > 15

        puts "--------#{i}---#{club.name}--------"
        next unless club.tm_url

        response = RestClient::Request.execute(method: :get, url: club.tm_url, headers: { 'User-Agent': 'product/version' },
                                               verify_ssl: false)
        html_page = Nokogiri::HTML(response)
        players = html_page.css('.inline-table .hauptlink')
        player_count = 1
        actual_ids = []
        players.each do |player_data|
          href = player_data.children[1].attributes['href'].value
          tm_id = href.split('/').last
          actual_ids << tm_id.to_i
          pl = Player.find_by(tm_id: tm_id)

          if pl
            change = pl.club.name == club.name ? '' : " >>>> #{club.name}"
            puts "#{player_count} - #{pl.name} - #{pl.id} / #{pl.tm_id} --- #{pl.club.name}#{change}"
            player_count += 1
          else
            puts "NEW .... #{tm_id}"
            begin
              result = Players::Transfermarkt::Parser.call(tm_id)
              next unless result

              writer << ['', result[:first_name], result[:name], result[:nationality], club.name,
                         result[:position1], result[:position2], result[:position3], result[:tm_url], '',
                         result[:tm_pos1], result[:tm_pos2], result[:tm_pos3], result[:tm_price]]
            rescue RestClient::Exception => e
              puts "error for id #{tm_id} - #{e}"
              writer << [tm_id]
            end

            sleep(2)
          end
        end
        puts '------------------'
        missed_ids = club.players.pluck(:tm_id).uniq - actual_ids
        missed_ids.each do |pl_tm_id|
          player = club.players.find_by(tm_id: pl_tm_id)
          begin
            result = Players::Transfermarkt::Parser.call(pl_tm_id)
            puts "#{player.name} - #{player.id} / #{player.tm_id} --- #{player.club.name} >>>> #{result[:club_name]}"
            sleep(2)
          rescue RestClient::Exception => e
            puts "CHANGE .... #{player.name} - #{player.id} / #{player.tm_id} - error: #{e}"
          end
        end
        puts '/////////////////////////////////////'

        sleep(5)
      end
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
