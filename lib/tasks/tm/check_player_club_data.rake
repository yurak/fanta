namespace :tm do
  desc 'Check TM player club data'
  task :check_player_club_data, %i[start_id last_id] => :environment do |_t, args|
    ids_range = args[:start_id].to_i..args[:last_id].to_i
    ids_range.to_a.each do |id|
      player = Player.find_by(id: id)
      next unless player&.tm_id

      p id if (id % 4).zero?
      html_page = Nokogiri::HTML(RestClient.get(player.tm_path))
      tm_club_name = html_page.css('.data-header__club').children[1]&.text
      tm_club_name = html_page.css('.data-header__club').children[0]&.text&.strip if tm_club_name.nil?
      club = Club.find_by(tm_name: tm_club_name)
      player_data = "Player #{player.id} / #{player.tm_id} #{player.name}"

      if club && tm_club_name != player.club.tm_name
        puts "#{player_data} (#{player.club.name}) changes club to #{tm_club_name}"
      elsif tm_club_name == 'Without Club'
        puts "#{player_data} (#{player.club.name}) currently is FREE" if player.club.name != 'Free agent'
      elsif player.club.name != 'Retired' && tm_club_name.nil?
        puts "#{player_data} retired!"
      elsif player.club.name != 'Outside' && player.club.name != 'Retired' && club.nil?
        puts "#{player_data} (#{player.club.name}) leave Mantra tournaments. New club: #{tm_club_name}"
      end

      sleep(20) if (id % 4).zero?
    end
  end
end
