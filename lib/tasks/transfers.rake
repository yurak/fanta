namespace :transfers do
  # rake transfers:outgoing_active_league
  desc 'Complete outgoing transfers for active league with auction deadline'
  task outgoing_active_league: :environment do
    League.active.each do |league|
      auction = league.auctions.sales.last
      next unless auction
      next if auction.deadline.nil? || auction.deadline.asctime.in_time_zone('EET') > DateTime.now

      puts league.name
      ActiveRecord::Base.transaction do
        league.teams.each do |team|
          team.player_teams.transferable.each do |pt|
            puts "Transfer: #{pt.player.name} (#{pt.player.id}) from #{team.name}"
            Transfers::Seller.call(pt.player, team, :outgoing)
          end
        end
      end

      Auctions::Manager.call(auction, league.auction_type)
    end
  end

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
