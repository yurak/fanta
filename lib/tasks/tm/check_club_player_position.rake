# rubocop:disable Metrics/BlockLength:
namespace :tm do
  # rake 'tm:check_club_player_position[2]'
  desc 'Check TM players position and write to csv if diff'
  task :check_club_player_position, %i[tournament_id] => :environment do |_t, args|
    clubs = args[:tournament_id] ? Club.active.where(tournament_id: args[:tournament_id]).order(:name) : Club.active.order(:tournament_id)

    CSV.open('log/player_position.csv', 'ab') do |writer|
      writer << ['id', 'name', 'club', 'tm_url', 'actual positions', 'recommended positions']
      clubs.limit(33).each do |club|
        puts "--------#{club.name}--------"
        club.players.each do |pl|
          res = Players::Transfermarkt::PositionMapper.call(pl, 2023)
          pos = pl.player_positions.map { |pp| Slot::POS_MAPPING[pp.position.name] }
          if res
            unless (res & pos) == res
              writer << [pl.id, pl.name, club.name, pl.tm_url, pos.join(','), res.join(','), pl.current_average_price]
            end
          else
            writer << [pl.id, pl.name, club.name, pl.tm_url, pos.join(','), 'NO RESULT', pl.current_average_price]
          end
        end
      end
    end
  end

  # rake 'tm:check_player_position_two_season[2]'
  desc 'Check TM players position for 2 seasons and write to csv if diff'
  task :check_player_position_two_season, %i[tournament_id] => :environment do |_t, args|
    clubs = args[:tournament_id] ? Club.active.where(tournament_id: args[:tournament_id]).order(:name) : Club.active.order(:tournament_id)

    CSV.open('log/player_position.csv', 'ab') do |writer|
      writer << ['id', 'name', 'club', 'tm_url', 'actual positions', 'recommended positions 22/23', 'recommended positions 23/24']
      clubs.limit(33).each do |club|
        puts "--------#{club.name}--------"
        club.players.each do |pl|
          res = Players::Transfermarkt::PositionMapper.call(pl, 2022)
          res2 = Players::Transfermarkt::PositionMapper.call(pl, 2023)
          pos = pl.player_positions.map { |pp| Slot::POS_MAPPING[pp.position.name] }
          if res && res2
            unless (res2 & pos) == res2
              writer << [pl.id, pl.name, club.name, pl.tm_url, pos.join(','), res.join(','), res2.join(','), pl.current_average_price]
            end
          elsif res2
            unless (res2 & pos) == res2
              writer << [pl.id, pl.name, club.name, pl.tm_url, pos.join(','), 'NO RESULT', res2.join(','), pl.current_average_price]
            end
          elsif res
            unless (res & pos) == res
              writer << [pl.id, pl.name, club.name, player.tm_url, pos.join(','), res.join(','), 'NO RESULT', pl.current_average_price]
            end
          else
            writer << [pl.id, pl.name, club.name, pl.tm_url, pos.join(','), 'NO RESULT', 'NO RESULT', pl.current_average_price]
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
