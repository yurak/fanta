# rubocop:disable Metrics/BlockLength:
namespace :transfers do
  # rake transfers:outgoing_active_league
  desc 'Complete outgoing transfers for active league with auction deadline'
  task outgoing_active_league: :environment do
    League.active.each do |league|
      Transfers::OutgoingProcessor.call(league)
    end
  end

  # rake 'transfers:league_transfer_list[1]'
  desc 'Show league outgoing transfer lists'
  task :league_transfer_list, [:league_id] => :environment do |_t, args|
    league = League.find_by(id: args[:league_id])
    return unless league

    puts league.name
    league.teams.each do |team|
      puts "----#{team.name}----"

      team.player_teams.transferable.each do |pt|
        puts "#{pt.player.name} (#{pt.player.id})"
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
