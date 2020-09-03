namespace :teams do
  desc 'Reset teams players'
  task reset: :environment do
    Team.all.each do |team|
      team.players.clear
    end
    puts 'Done!'
  end
end
