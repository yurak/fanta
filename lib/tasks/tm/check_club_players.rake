# rubocop:disable Metrics/BlockLength:
namespace :tm do
  # rake 'tm:check_club_players_csv[15]'
  desc 'Check TM players list from club pages and write to csv'
  task :check_club_players_csv, %i[tournament_id] => :environment do |_t, args|
    clubs = args[:tournament_id] ? Club.active.where(tournament_id: args[:tournament_id]).order(:name) : Club.active.order(:name)

    CSV.open('log/club_players.csv', 'ab') do |writer|
      clubs.each do |club|
        puts "--------#{club.name}--------"
        next unless club.tm_url

        response = RestClient::Request.execute(method: :get, url: club.tm_url, headers: { 'User-Agent': 'product/version' },
                                               verify_ssl: false)
        html_page = Nokogiri::HTML(response)
        players = html_page.css('.inline-table .hauptlink')
        player_count = 1

        players.each do |player_data|
          # player_name = player_data.children.first.attributes['title'].value
          href = player_data.children[1].attributes['href'].value
          player_url = "https://www.transfermarkt.com#{href}"
          tm_id = href.split('/').last
          player = Player.find_by(tm_id: tm_id)

          if player
            puts "#{player_count} - #{player.name} - #{player.tm_id} --- #{player.club.name}"
            player_count += 1
          else
            player_response = RestClient::Request.execute(method: :get, url: player_url, headers: { 'User-Agent': 'product/version' },
                                                          verify_ssl: false)
            player_page = Nokogiri::HTML(player_response)

            name_data = player_page.css('.data-header__headline-wrapper').children
            if name_data[1]&.text&.strip&.tr('#', '').to_i.positive?
              first_name = name_data[2]&.text&.strip
              last_name = name_data[3]&.text&.strip
            else
              first_name = name_data[0]&.text&.strip
              last_name = name_data[1]&.text&.strip
            end
            country_name = player_page.css('.data-header__items .data-header__content .flaggenrahmen')[0].attributes['title'].value
            country = ISO3166::Country.find_country_by_iso_short_name(country_name)&.alpha2&.downcase
            positions = player_page.css('.detail-position__position')
            tm_pos1 = Position::TM_POS[positions[0]&.text]
            tm_pos2 = Position::TM_POS[positions[2]&.text]
            tm_pos3 = Position::TM_POS[positions[3]&.text]

            position_arr = Players::Transfermarkt::PositionMapper.call(Player.new(tm_id: tm_id), 2023)
            pos1 = tm_pos1 == 'GK' ? 'Por' : ''
            pos1 = Position::HUMAN_MAP[position_arr[0]] if position_arr[0]
            pos2 = position_arr[1] ? Position::HUMAN_MAP[position_arr[1]] : nil
            pos3 = position_arr[2] ? Position::HUMAN_MAP[position_arr[2]] : nil
            price_data = player_page.css('.data-header__market-value-wrapper').children
            price = price_data[1]&.text.to_s + price_data[2]&.text.to_s

            writer << ['', first_name, last_name, country, club.name, pos1, pos2, pos3, player_url, '', tm_pos1, tm_pos2, tm_pos3, price]

            sleep(5)
          end
        end

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
