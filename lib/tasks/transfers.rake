namespace :transfers do
  desc 'Complete outgoing transfers for league'
  task :outgoing, [:league_id] => :environment do |_t, args|
    league = League.find_by(id: args[:league_id])
    return unless league

    puts league.name
    league.teams.each do |team|
      puts "----#{team.name}----"

      team.player_teams.transferable.each do |pt|
        init_transfer = pt.player.transfer_by(team)
        next unless init_transfer

        puts "Transfer: #{pt.player.name} (#{pt.player.id}) from #{team.name}, price: #{init_transfer.price}"

        ActiveRecord::Base.transaction do
          Transfer.create(player: pt.player, team: team, league: league, price: init_transfer.price, status: :outgoing)
          team.update(budget: team.budget + init_transfer.price)
          pt.destroy
        end
      end
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
