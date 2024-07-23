# rubocop:disable Metrics/BlockLength:
namespace :tm do
  # rake 'tm:check_player_club_data[start_id,last_id]'
  desc 'Check TM player club data'
  task :check_player_club_data, %i[start_id last_id] => :environment do |_t, args|
    ids_range = args[:start_id].to_i..args[:last_id].to_i

    CSV.open('log/player_changed_club.csv', 'ab') do |writer|
      ids_range.to_a.each do |id|
        player = Player.find_by(id: id)
        next unless player&.tm_id

        p id if (id % 4).zero?
        begin
          response = RestClient::Request.execute(method: :get, url: player.tm_path, headers: { 'User-Agent': 'product/version' },
                                                 verify_ssl: false)

          html_page = Nokogiri::HTML(response)
          tm_club_name = html_page.css('.data-header__club').children[1]&.text
          tm_club_name = html_page.css('.data-header__club').children[0]&.text&.strip if tm_club_name.nil?
          club = Club.find_by(tm_name: tm_club_name)
          club_res = Club.where('reserve_clubs LIKE ?', "%#{tm_club_name}%").first unless club
          player_data = "Player #{player.id} / #{player.tm_id} #{player.name}"

          result = if club_res && club_res == player.club
                     "#{player_data} (#{player.club.name}) in reserve"
                   elsif club && tm_club_name != player.club.tm_name
                     "#{player_data} (#{player.club.name}) changes club to #{tm_club_name}"
                   elsif tm_club_name == 'Without Club'
                     "#{player_data} (#{player.club.name}) currently is FREE" if player.club.name != 'Free agent'
                   elsif player.club.name != 'Retired' && tm_club_name.nil?
                     "#{player_data} retired!"
                   elsif player.club.name != 'Outside' && player.club.name != 'Retired' && club.nil?
                     "#{player_data} (#{player.club.name}) leave Mantra tournaments. New club: #{tm_club_name}"
                   end

          if result
            puts result
            writer << [result]
          end
          writer << [id] if (id % 100).zero?
        rescue RestClient::Exception => e
          puts "error for id #{player.id} / #{player.tm_id} - #{e}"
        end

        sleep(10) if (id % 4).zero?
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
