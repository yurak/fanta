namespace :transfers do
  desc 'Complete outgoing transfers for active league with auction deadline'
  task outgoing_active_league: :environment do
    League.active.each do |league|
      auction = league.auctions.sales.last
      next unless auction
      next if auction.deadline.asctime.in_time_zone('EET') > DateTime.now

      puts league.name
      ActiveRecord::Base.transaction do
        league.teams.each do |team|
          team.player_teams.transferable.each do |pt|
            puts "Transfer: #{pt.player.name} (#{pt.player.id}) from #{team.name}"
            Transfers::Seller.call(player: pt.player, team: team, status: :outgoing)
          end
        end
      end

      auction.send("#{league.auction_type}!")
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

  desc 'Generate auctions (temp task)'
  task generate_auctions: :environment do
    auctions_data = YAML.load_file(Rails.root.join('config/mantra/auctions.yml'))

    auctions_data.each do |league_data|
      league = League.find_by(id: league_data[0])
      next unless league

      league_data[1].each do |auc_data|
        auction = league.auctions.create(
          number: auc_data[0],
          deadline: Transfer.find_by(id: auc_data[1].first.to_i).created_at,
          event_time: Transfer.find_by(id: auc_data[1].last.to_i).created_at
        )

        transfer_ids = auc_data[1].map { |ids| ids.to_i == ids ? ids : ids.split('..').inject { |s, e| s.to_i..e.to_i }.to_a }.flatten

        transfer_ids.each do |t_id|
          transfer = Transfer.find_by(id: t_id)
          p "Transfer ##{t_id} is not found" unless transfer
          next unless transfer

          transfer.update(auction: auction)
        end
      end
    end
  end
end
