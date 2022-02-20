namespace :tm do
  desc 'Check TM player club data'
  task :check_player_club_data, %i[start_id last_id] => :environment do |_t, args|
    ids_range = args[:start_id].to_i..args[:last_id].to_i
    ids_range.to_a.each do |id|
      player = Player.find_by(id: id)
      next unless player&.tm_url

      p id
      html_page = Nokogiri::HTML(RestClient.get(player.tm_url))
      tm_club_name = html_page.css('.hauptpunkt').children.children.text
      club = Club.find_by(tm_name: tm_club_name)

      if club && tm_club_name != player.club.tm_name
        puts "Player #{player.id} #{player.name} changes club to #{tm_club_name}"
      elsif tm_club_name == ''
        puts "Player #{player.id} #{player.name} retired!"
      elsif player.club.name != 'xxx' && club.nil?
        puts "Player #{player.id} #{player.name} leave Mantra tournaments. New club: #{tm_club_name}"
      end
    end
  end

  desc 'Check TM players links from club pages'
  task :check_club_players, %i[id] => :environment do |_t, args|
    clubs = args[:id] ? Club.where(id: args[:id]) : Club.active.order(:name)

    clubs.each do |club|
      puts "--------#{club.name}--------"
      html_page = Nokogiri::HTML(RestClient.get(club.tm_url))
      players = html_page.css('.posrela .hauptlink .hide-for-small')

      players.each do |player_data|
        player_name = player_data.children.first.attributes['title'].value
        href = player_data.children.first.attributes['href'].value
        player_url = "https://www.transfermarkt.com#{href}"
        player = Player.find_by(tm_url: player_url)

        puts "#{player_name} - #{player_url}" unless player
      end
    end
  end
end
