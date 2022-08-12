namespace :tm do
  desc 'Check TM player club data'
  task :check_player_club_data, %i[start_id last_id] => :environment do |_t, args|
    ids_range = args[:start_id].to_i..args[:last_id].to_i
    ids_range.to_a.each do |id|
      player = Player.find_by(id: id)
      next unless player&.tm_id

      p id if (id % 20).zero?
      html_page = Nokogiri::HTML(RestClient.get(player.tm_path))
      tm_club_name = html_page.css('.data-header__club').children[1]&.text
      club = Club.find_by(tm_name: tm_club_name)

      if club && tm_club_name != player.club.tm_name
        puts "Player #{player.id} #{player.name} (#{player.club.name}) changes club to #{tm_club_name}"
      elsif tm_club_name == 'Without Club'
        puts "Player #{player.id} #{player.name} (#{player.club.name}) currently is FREE" if player.club.name != 'Free agent'
      elsif player.club.name != 'Retired' && tm_club_name.nil?
        puts "Player #{player.id} #{player.name} retired!"
      elsif player.club.name != 'Outside' && player.club.name != 'Retired' && club.nil?
        puts "Player #{player.id} #{player.name} (#{player.club.name}) leave Mantra tournaments. New club: #{tm_club_name}"
      end
    end
  end
end
